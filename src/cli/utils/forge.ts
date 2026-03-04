import execa from 'execa'
import * as fs from 'fs'
import * as path from 'path'
import { die, log } from './log'
import { getRepoRoot } from './env'

export interface ForgeScriptOptions {
  script: string
  rpcUrl: string
  authArgs?: string
  broadcast?: boolean
  verify?: boolean
  slow?: boolean
  skipSimulation?: boolean
  verbosity?: number
  env?: Record<string, string>
}

export async function runForgeScript(
  options: ForgeScriptOptions
): Promise<void> {
  const args = ['script', options.script, '--rpc-url', options.rpcUrl]

  if (options.slow) {
    args.push('--slow')
  }

  if (options.skipSimulation) {
    args.push('--skip-simulation')
  }

  const verbosity = options.verbosity ?? 3
  args.push('-' + 'v'.repeat(verbosity))

  if (options.broadcast && options.authArgs) {
    args.push('--broadcast')
    args.push(...options.authArgs.split(' ').filter(Boolean))
  }

  if (options.verify) {
    args.push('--verify')
  }

  log(`Running: forge ${args.slice(0, 2).join(' ')}...`)

  const result = await execa('forge', args, {
    stdio: 'inherit',
    env: { ...process.env, ...options.env },
  })

  if (result.exitCode !== 0) {
    die(`Forge script failed with exit code ${result.exitCode}`)
  }
}

export interface CastSendOptions {
  to: string
  sig: string
  args: string[]
  rpcUrl: string
  authArgs?: string
}

export async function runCastSend(options: CastSendOptions): Promise<void> {
  const args = [
    'send',
    options.to,
    options.sig,
    ...options.args,
    '--rpc-url',
    options.rpcUrl,
  ]

  if (options.authArgs) {
    args.push(...options.authArgs.split(' ').filter(Boolean))
  }

  const result = await execa('cast', args, {
    stdio: 'inherit',
    env: process.env,
  })

  if (result.exitCode !== 0) {
    die(`Cast send failed with exit code ${result.exitCode}`)
  }
}

export interface CastCallOptions {
  to: string
  sig: string
  rpcUrl: string
}

export async function runCastCall(options: CastCallOptions): Promise<string> {
  try {
    const result = await execa('cast', [
      'call',
      '--rpc-url',
      options.rpcUrl,
      options.to,
      options.sig,
    ])
    return result.stdout
  } catch {
    return 'N/A'
  }
}

export async function castCalldata(
  sig: string,
  ...args: string[]
): Promise<string> {
  const result = await execa('cast', ['calldata', sig, ...args])
  return result.stdout
}

export async function getChainId(rpcUrl: string): Promise<string> {
  const result = await execa('cast', ['chain-id', '--rpc-url', rpcUrl])
  return result.stdout.trim()
}

export function parseActionAddress(
  scriptPath: string,
  chainId: string
): string {
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
    die(`Broadcast file not found: ${broadcastFile}`)
  }

  const content = JSON.parse(fs.readFileSync(broadcastFile, 'utf-8'))
  const createTxs = content.transactions?.filter(
    (tx: { transactionType: string }) => tx.transactionType === 'CREATE'
  )

  if (!createTxs || createTxs.length === 0) {
    die('Could not parse action address from broadcast file')
  }

  const address = createTxs[createTxs.length - 1]?.contractAddress
  if (!address) {
    die('Could not parse action address from broadcast file')
  }

  return address
}

export function findScript(dir: string, pattern: RegExp): string | null {
  if (!fs.existsSync(dir)) {
    return null
  }

  const files = fs.readdirSync(dir)
  for (const file of files) {
    if (pattern.test(file) && file.endsWith('.s.sol')) {
      return path.join(dir, file)
    }
  }
  return null
}
