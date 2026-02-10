import * as path from 'path'
import * as fs from 'fs'
import { log, die } from '../utils/log'
import { requireEnv, getEnv, getScriptsDir } from '../utils/env'
import {
  parseAuthArgs,
  createDeployExecuteAuth,
  getDeployAuth,
  getExecuteAuth,
} from '../utils/auth'
import {
  runForgeScript,
  runCastSend,
  runCastCall,
  castCalldata,
  getChainId,
  parseActionAddress,
} from '../utils/forge'

const ARBOS_DIR = path.join(getScriptsDir(), 'arbos-upgrades', 'at-timestamp')
const DEPLOY_SCRIPT = path.join(
  ARBOS_DIR,
  'DeployUpgradeArbOSVersionAtTimestampAction.s.sol'
)

// ArbOS precompile addresses
const ARB_OWNER_PUBLIC = '0x000000000000000000000000000000000000006b'
const ARB_SYS = '0x0000000000000000000000000000000000000064'

// Nitro ArbOS versions are offset by 55 to avoid collision with classic (pre-Nitro) versions
const ARBOS_VERSION_OFFSET = 55
const PERFORM_SELECTOR = '0xb0a75d36'

function checkDeployScript(): void {
  if (!fs.existsSync(DEPLOY_SCRIPT)) {
    die(`Deploy script not found: ${DEPLOY_SCRIPT}`)
  }
}

async function deployAction(
  version: string,
  rpcUrl: string,
  authArgs: string,
  options: { broadcast: boolean; verify?: boolean }
): Promise<void> {
  checkDeployScript()
  process.env.ARBOS_VERSION = version

  await runForgeScript({
    script: DEPLOY_SCRIPT,
    rpcUrl,
    authArgs,
    broadcast: options.broadcast,
    verify: options.verify,
    slow: true,
  })
}

async function executeUpgrade(
  actionAddress: string,
  upgradeExecutor: string,
  rpcUrl: string,
  authArgs: string,
  dryRun: boolean
): Promise<void> {
  if (dryRun || !authArgs) {
    const executeCalldata = await castCalldata(
      'execute(address,bytes)',
      actionAddress,
      PERFORM_SELECTOR
    )

    log(
      dryRun
        ? 'Dry run - calldata for UpgradeExecutor.execute():'
        : 'Calldata for UpgradeExecutor.execute():'
    )
    console.log('')
    console.log(`To: ${upgradeExecutor}`)
    console.log(`Calldata: ${executeCalldata}`)
    console.log('')
    log('Submit this to your multisig/Safe to execute the upgrade')
  } else {
    await runCastSend({
      to: upgradeExecutor,
      sig: 'execute(address,bytes)',
      args: [actionAddress, PERFORM_SELECTOR],
      rpcUrl,
      authArgs,
    })

    log('ArbOS upgrade scheduled successfully')
  }
}

async function verifyUpgrade(rpcUrl: string): Promise<void> {
  log('Checking ArbOS upgrade status...')

  const scheduled = await runCastCall({
    to: ARB_OWNER_PUBLIC,
    sig: 'getScheduledUpgrade()(uint64,uint64)',
    rpcUrl,
  })
  log(`Scheduled upgrade (version, timestamp): ${scheduled}`)

  const currentRaw = await runCastCall({
    to: ARB_SYS,
    sig: 'arbOSVersion()(uint64)',
    rpcUrl,
  })

  let currentVersion: number
  if (currentRaw === 'N/A') {
    currentVersion = 0
  } else {
    const rawNum = parseInt(currentRaw, 10)
    currentVersion = rawNum - ARBOS_VERSION_OFFSET
  }

  log(`Current ArbOS version: ${currentVersion}`)
}

async function cmdDeploy(version: string, args: string[]): Promise<void> {
  const authArgs = parseAuthArgs(args)
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  log(`Running: ${path.basename(DEPLOY_SCRIPT)} for ArbOS ${version}`)
  await deployAction(version, rpcUrl, authArgs, {
    broadcast: Boolean(authArgs),
  })
}

async function cmdExecute(args: string[]): Promise<void> {
  const authArgs = parseAuthArgs(args)

  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  const upgradeExecutor = requireEnv('CHILD_UPGRADE_EXECUTOR_ADDRESS')
  const actionAddress = requireEnv('UPGRADE_ACTION_ADDRESS')

  log(`Executing ArbOS upgrade action: ${actionAddress}`)

  await executeUpgrade(actionAddress, upgradeExecutor, rpcUrl, authArgs, false)
}

async function cmdVerify(): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  await verifyUpgrade(rpcUrl)
}

async function cmdDeployExecuteVerify(
  version: string,
  options: {
    deployKey?: string
    deployAccount?: string
    deployLedger?: boolean
    deployInteractive?: boolean
    executeKey?: string
    executeAccount?: string
    executeLedger?: boolean
    executeInteractive?: boolean
    dryRun?: boolean
    skipExecute?: boolean
    verify?: boolean
  }
): Promise<void> {
  const auth = createDeployExecuteAuth(options)

  log(`ArbOS version: ${version}`)
  checkDeployScript()

  const skipDeploy = Boolean(getEnv('UPGRADE_ACTION_ADDRESS'))
  let upgradeActionAddress = getEnv('UPGRADE_ACTION_ADDRESS') || ''

  if (skipDeploy) {
    log(`Using existing action from .env: ${upgradeActionAddress}`)
  }

  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  const upgradeExecutor = requireEnv('CHILD_UPGRADE_EXECUTOR_ADDRESS')
  requireEnv('SCHEDULE_TIMESTAMP')

  const deployAuth = getDeployAuth(auth)
  const executeAuth = getExecuteAuth(auth)

  if (!skipDeploy && !auth.dryRun && !deployAuth) {
    die(
      'Deploy auth required. Use --deploy-key, --deploy-account, --deploy-ledger, or --deploy-interactive'
    )
  }
  if (!auth.skipExecute && !auth.dryRun && !executeAuth) {
    die(
      'Execute auth required. Use --execute-key, --execute-account, --execute-ledger, or --execute-interactive'
    )
  }

  log(`Scheduled timestamp: ${process.env.SCHEDULE_TIMESTAMP}`)

  let chainId = ''
  if (!skipDeploy) {
    chainId = await getChainId(rpcUrl)
    log(`Target chain ID: ${chainId}`)
    log('Step 1: Deploying ArbOS upgrade action...')

    await deployAction(version, rpcUrl, deployAuth, {
      broadcast: !auth.dryRun,
      verify: auth.verifyContracts,
    })

    if (!auth.dryRun) {
      upgradeActionAddress = parseActionAddress(DEPLOY_SCRIPT, chainId)
      log(`Deployed action at: ${upgradeActionAddress}`)
    } else {
      log('Dry run - no action deployed')
      if (!auth.skipExecute) {
        log('Note: Set UPGRADE_ACTION_ADDRESS in .env to run execute step')
        return
      }
    }
  } else {
    log('Step 1: Skipped deploy')
  }

  if (!auth.skipExecute) {
    log('Step 2: Executing ArbOS upgrade...')
    await executeUpgrade(
      upgradeActionAddress,
      upgradeExecutor,
      rpcUrl,
      executeAuth,
      auth.dryRun
    )
  } else {
    log('Step 2: Skipped execute')
  }

  if (!auth.dryRun && !auth.skipExecute) {
    log('Step 3: Verifying scheduled upgrade...')
    await verifyUpgrade(rpcUrl)
  }

  log('Done')
}

export { cmdDeploy, cmdExecute, cmdVerify, cmdDeployExecuteVerify }
