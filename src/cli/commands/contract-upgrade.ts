import * as path from 'path'
import * as fs from 'fs'
import { die } from '../utils/log'
import { requireEnv, getScriptsDir } from '../utils/env'
import {
  runForgeScript,
  getChainId,
  parseActionAddress,
  findScript,
} from '../utils/forge'

const CONTRACTS_DIR = path.join(getScriptsDir(), 'contract-upgrades')

function getVersionDir(version: string): string {
  const versionDir = path.join(CONTRACTS_DIR, version)
  if (!fs.existsSync(versionDir)) {
    const available = fs.existsSync(CONTRACTS_DIR)
      ? fs
          .readdirSync(CONTRACTS_DIR)
          .filter(f => !f.startsWith('.'))
          .join(' ')
      : 'none found'
    die(`Unknown version: ${version}\n\nAvailable versions: ${available}`)
  }
  return versionDir
}

async function cmdDeploy(version: string): Promise<void> {
  const versionDir = getVersionDir(version)

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC')

  const deployScript = findScript(versionDir, /^Deploy.*\.s\.sol$/)
  if (!deployScript) {
    die(`No deploy script found in ${versionDir}`)
  }

  console.log(`Running: ${path.basename(deployScript)}`)

  await runForgeScript({
    script: deployScript,
    rpcUrl,
  })

  const chainId = await getChainId(rpcUrl)
  const address = parseActionAddress(deployScript, chainId)
  if (address) {
    console.log(`Deployed action address: ${address}`)
    console.log('Run execute next, or set UPGRADE_ACTION_ADDRESS in .env to override')
  }
}

async function resolveActionAddress(
  versionDir: string,
  rpcUrl: string
): Promise<string> {
  const fromEnv = process.env.UPGRADE_ACTION_ADDRESS
  if (fromEnv) return fromEnv

  const deployScript = findScript(versionDir, /^Deploy.*\.s\.sol$/)
  if (deployScript) {
    const chainId = await getChainId(rpcUrl)
    const fromBroadcast = parseActionAddress(deployScript, chainId)
    if (fromBroadcast) return fromBroadcast
  }

  die(
    'Could not resolve action address.\n' +
      'Either set UPGRADE_ACTION_ADDRESS in .env, or run deploy first.'
  )
}

async function cmdExecute(version: string): Promise<void> {
  const versionDir = getVersionDir(version)
  const rpcUrl = requireEnv('PARENT_CHAIN_RPC')
  const actionAddress = await resolveActionAddress(versionDir, rpcUrl)

  const executeScript = findScript(versionDir, /^Execute.*\.s\.sol$/)
  if (!executeScript) {
    die(`No execute script found in ${versionDir}`)
  }

  console.log(`Using action address: ${actionAddress}`)
  console.log(`Running: ${path.basename(executeScript)}`)

  await runForgeScript({
    script: executeScript,
    rpcUrl,
    env: { UPGRADE_ACTION_ADDRESS: actionAddress },
  })
}

async function cmdVerify(version: string): Promise<void> {
  const versionDir = getVersionDir(version)

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC')

  const verifyScript = findScript(versionDir, /^Verify.*\.s\.sol$/)
  if (!verifyScript) {
    die(
      `No verify script found in ${versionDir} - check README for manual verification`
    )
  }

  console.log(`Running: ${path.basename(verifyScript)}`)

  await runForgeScript({
    script: verifyScript,
    rpcUrl,
  })
}

export { cmdDeploy, cmdExecute, cmdVerify, getVersionDir }
