import * as path from 'path'
import * as fs from 'fs'
import { Interface } from 'ethers'
import { log, die } from '../utils/log'
import { requireEnv, getScriptsDir } from '../utils/env'
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
const PERFORM_SELECTOR = new Interface(['function perform()']).getFunction(
  'perform'
)!.selector

function checkDeployScript(): void {
  if (!fs.existsSync(DEPLOY_SCRIPT)) {
    die(`Deploy script not found: ${DEPLOY_SCRIPT}`)
  }
}

async function deployAction(
  version: string,
  rpcUrl: string
): Promise<void> {
  checkDeployScript()

  await runForgeScript({
    script: DEPLOY_SCRIPT,
    rpcUrl,
    env: { ARBOS_VERSION: version },
  })
}

async function executeUpgrade(
  actionAddress: string,
  upgradeExecutor: string,
  rpcUrl: string
): Promise<void> {
  const executeCalldata = await castCalldata(
    'execute(address,bytes)',
    actionAddress,
    PERFORM_SELECTOR
  )

  log('Calldata for UpgradeExecutor.execute():')
  console.log('')
  console.log(`To: ${upgradeExecutor}`)
  console.log(`Calldata: ${executeCalldata}`)
  console.log('')
  log('Submit this to your multisig/Safe to execute the upgrade')

  if (process.env.FOUNDRY_BROADCAST) {
    log('Broadcasting transaction...')
    await runCastSend({
      to: upgradeExecutor,
      sig: 'execute(address,bytes)',
      args: [actionAddress, PERFORM_SELECTOR],
      rpcUrl,
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
  log(`Scheduled upgrade (version, timestamp): (${scheduled.replace('\n', ', ')})`)

  const currentRaw = await runCastCall({
    to: ARB_SYS,
    sig: 'arbOSVersion()(uint64)',
    rpcUrl,
  })

  const currentVersion = parseInt(currentRaw, 10) - ARBOS_VERSION_OFFSET

  log(`Current ArbOS version: ${currentVersion}`)
}

async function cmdDeploy(version: string): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  log(`Running: ${path.basename(DEPLOY_SCRIPT)} for ArbOS ${version}`)
  await deployAction(version, rpcUrl)

  const chainId = await getChainId(rpcUrl)
  const address = parseActionAddress(DEPLOY_SCRIPT, chainId)
  if (address) {
    log(`Deployed action address: ${address}`)
    log('Set UPGRADE_ACTION_ADDRESS in .env for the execute step')
  }
}

async function cmdExecute(): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  const upgradeExecutor = requireEnv('CHILD_UPGRADE_EXECUTOR_ADDRESS')
  const actionAddress = requireEnv('UPGRADE_ACTION_ADDRESS')

  log(`Executing ArbOS upgrade action: ${actionAddress}`)

  await executeUpgrade(actionAddress, upgradeExecutor, rpcUrl)
}

async function cmdVerify(): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  await verifyUpgrade(rpcUrl)
}

export { cmdDeploy, cmdExecute, cmdVerify }
