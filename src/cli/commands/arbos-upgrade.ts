import * as path from 'path'
import * as fs from 'fs'
import { Interface } from 'ethers'
import { die } from '../utils/log'
import { requireEnv, getScriptsDir } from '../utils/env'
import {
  runForgeScript,
  runCastSend,
  runCastCall,
  resolveActionAddress,
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

async function deployAction(version: string, rpcUrl: string): Promise<void> {
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
  const iface = new Interface(['function execute(address,bytes)'])
  const calldata = iface.encodeFunctionData('execute', [
    actionAddress,
    PERFORM_SELECTOR,
  ])

  console.log('Calldata for UpgradeExecutor.execute():')
  console.log('')
  console.log(`To: ${upgradeExecutor}`)
  console.log(`Calldata: ${calldata}`)

  if (process.env.FOUNDRY_BROADCAST) {
    console.log('Broadcasting transaction...')
    await runCastSend({ to: upgradeExecutor, data: calldata, rpcUrl })

    console.log('ArbOS upgrade scheduled successfully')
  } else {
    console.log(
      'Set FOUNDRY_BROADCAST=true in .env to broadcast this transaction.'
    )
  }
}

async function verifyUpgrade(rpcUrl: string): Promise<void> {
  console.log('Checking ArbOS upgrade status...')

  const scheduledIface = new Interface([
    'function getScheduledUpgrade() view returns (uint64, uint64)',
  ])
  const scheduledRaw = await runCastCall({
    to: ARB_OWNER_PUBLIC,
    data: scheduledIface.encodeFunctionData('getScheduledUpgrade'),
    rpcUrl,
  })
  const [version, timestamp] = scheduledIface.decodeFunctionResult(
    'getScheduledUpgrade',
    scheduledRaw
  )
  console.log(
    `Scheduled upgrade (version, timestamp): (${version}, ${timestamp})`
  )

  const arbSysIface = new Interface([
    'function arbOSVersion() view returns (uint64)',
  ])
  const versionRaw = await runCastCall({
    to: ARB_SYS,
    data: arbSysIface.encodeFunctionData('arbOSVersion'),
    rpcUrl,
  })
  const [currentVersionRaw] = arbSysIface.decodeFunctionResult(
    'arbOSVersion',
    versionRaw
  )
  const currentVersion = Number(currentVersionRaw) - ARBOS_VERSION_OFFSET

  console.log(`Current ArbOS version: ${currentVersion}`)
}

async function cmdDeploy(version: string): Promise<void> {
  if (process.env.UPGRADE_ACTION_ADDRESS) {
    console.log(
      `Action already deployed at: ${process.env.UPGRADE_ACTION_ADDRESS}`
    )
    console.log(
      'Run execute next, or remove UPGRADE_ACTION_ADDRESS from .env to redeploy.'
    )
    return
  }
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  console.log(`Running: ${path.basename(DEPLOY_SCRIPT)} for ArbOS ${version}`)
  await deployAction(version, rpcUrl)

  if (!process.env.FOUNDRY_BROADCAST) {
    console.log(
      'Rerun with FOUNDRY_BROADCAST=true to deploy, then run execute.'
    )
    return
  }

  const address = await resolveActionAddress(DEPLOY_SCRIPT, rpcUrl)
  console.log(`Deployed action address: ${address}`)
  console.log(
    'Run "execute" next, or set UPGRADE_ACTION_ADDRESS in .env to override'
  )
}

async function cmdExecute(): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  const upgradeExecutor = requireEnv('CHILD_UPGRADE_EXECUTOR_ADDRESS')
  const actionAddress = await resolveActionAddress(DEPLOY_SCRIPT, rpcUrl)

  console.log(`Executing ArbOS upgrade action: ${actionAddress}`)

  await executeUpgrade(actionAddress, upgradeExecutor, rpcUrl)
}

async function cmdVerify(): Promise<void> {
  const rpcUrl = requireEnv('CHILD_CHAIN_RPC')
  await verifyUpgrade(rpcUrl)
}

export { cmdDeploy, cmdExecute, cmdVerify }
