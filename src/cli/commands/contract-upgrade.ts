import * as path from 'path'
import * as fs from 'fs'
import { die } from '../utils/log'
import { requireEnv, getScriptsDir } from '../utils/env'
import {
  runForgeScript,
  resolveActionAddress,
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
  if (process.env.UPGRADE_ACTION_ADDRESS) {
    console.log(
      `Action already deployed at: ${process.env.UPGRADE_ACTION_ADDRESS}`
    )
    console.log(
      'Run execute next, or remove UPGRADE_ACTION_ADDRESS from .env to redeploy.'
    )
    return
  }

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

  if (!process.env.FOUNDRY_BROADCAST) {
    console.log(
      'Rerun with FOUNDRY_BROADCAST=true to deploy, then run execute.'
    )
    return
  }

  const address = await resolveActionAddress(deployScript, rpcUrl)
  console.log(`Deployed action address: ${address}`)
  console.log(
    'Run execute next, or set UPGRADE_ACTION_ADDRESS in .env to override'
  )
}

async function cmdExecute(version: string): Promise<void> {
  const versionDir = getVersionDir(version)
  const rpcUrl = requireEnv('PARENT_CHAIN_RPC')
  const deployScript = findScript(versionDir, /^Deploy.*\.s\.sol$/)
  if (!deployScript && !process.env.UPGRADE_ACTION_ADDRESS) {
    die(
      `No deploy script found in ${versionDir}.\n` +
        'Set UPGRADE_ACTION_ADDRESS in .env to provide the action address manually.'
    )
  }
  const actionAddress = await resolveActionAddress(deployScript, rpcUrl)

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
