import execa from 'execa'
import * as fs from 'fs'
import * as path from 'path'
import { die } from './log'
import { getRepoRoot } from './env'

export interface ForgeScriptOptions {
  script: string
  rpcUrl: string
  env?: Record<string, string>
}

export async function runForgeScript(
  options: ForgeScriptOptions
): Promise<void> {
  const args = ['script', options.script, '--rpc-url', options.rpcUrl]

  console.log(`Running: forge ${args.join(' ')}`)

  try {
    await execa('forge', args, {
      stdio: 'inherit',
      env: { ...process.env, ...options.env },
    })
  } catch {
    die('Forge script failed')
  }
}

export interface CastSendOptions {
  to: string
  data: string
  rpcUrl: string
}

export async function runCastSend(options: CastSendOptions): Promise<void> {
  try {
    await execa(
      'cast',
      ['send', options.to, '--data', options.data, '--rpc-url', options.rpcUrl],
      { stdio: 'inherit' }
    )
  } catch {
    die('Cast send failed')
  }
}

export interface CastCallOptions {
  to: string
  data: string
  rpcUrl: string
}

export async function runCastCall(options: CastCallOptions): Promise<string> {
  try {
    const result = await execa(
      'cast',
      ['call', options.to, '--data', options.data, '--rpc-url', options.rpcUrl],
      { stderr: 'inherit' }
    )
    return result.stdout
  } catch {
    die(`cast call failed on ${options.to}`)
  }
}

export async function getChainId(rpcUrl: string): Promise<string> {
  try {
    const result = await execa('cast', ['chain-id', '--rpc-url', rpcUrl], {
      stderr: 'inherit',
    })
    return result.stdout.trim()
  } catch {
    die(`Failed to get chain ID from ${rpcUrl}`)
  }
}

// Assumes the action contract is the last CREATE in the broadcast file.
// This holds for all current deploy scripts, which deploy dependencies first
// and the action contract last.
function parseActionAddress(
  scriptPath: string,
  chainId: string
): string | null {
  const scriptName = path.basename(scriptPath)
  const repoRoot = getRepoRoot()
  const broadcastFile = path.join(
    repoRoot,
    'broadcast',
    scriptName,
    chainId,
    'run-latest.json'
  )

  if (!fs.existsSync(broadcastFile)) {
    return null
  }

  const content = JSON.parse(fs.readFileSync(broadcastFile, 'utf-8'))
  const createTxs = content.transactions?.filter(
    (tx: { transactionType: string }) => tx.transactionType === 'CREATE'
  )

  if (!createTxs || createTxs.length === 0) {
    return null
  }

  return createTxs[createTxs.length - 1]?.contractAddress ?? null
}

export async function resolveActionAddress(
  deployScript: string | null,
  rpcUrl: string
): Promise<string> {
  const fromEnv = process.env.UPGRADE_ACTION_ADDRESS
  if (fromEnv) return fromEnv

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

export function findScript(dir: string, pattern: RegExp): string | null {
  if (!fs.existsSync(dir)) {
    return null
  }

  const files = fs.readdirSync(dir)
  for (const file of files) {
    if (pattern.test(file)) {
      return path.join(dir, file)
    }
  }
  return null
}
