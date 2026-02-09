import * as dotenv from 'dotenv'
import * as fs from 'fs'
import * as path from 'path'
import { die } from './log'

function findRepoRoot(): string | null {
  let dir = __dirname
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, 'package.json'))) {
      return dir
    }
    const parent = path.dirname(dir)
    if (parent === dir) break
    dir = parent
  }
  return null
}

export function loadEnv(): void {
  const repoRoot = findRepoRoot()
  const candidates = [
    path.join(process.cwd(), '.env'),
    repoRoot ? path.join(repoRoot, '.env') : null,
    '/app/.env',
  ].filter((p): p is string => p !== null)

  for (const envPath of candidates) {
    if (fs.existsSync(envPath)) {
      dotenv.config({ path: envPath })
      return
    }
  }
}

export function requireEnv(name: string): string {
  const value = process.env[name]
  if (!value) {
    die(`Required env var not set: ${name} (check your .env file)`)
  }
  return value
}

export function getEnv(name: string): string | undefined {
  return process.env[name]
}

export function getScriptsDir(): string {
  const repoRoot = findRepoRoot()
  if (repoRoot) {
    return path.join(repoRoot, 'scripts', 'foundry')
  }
  return '/app/scripts/foundry'
}

export function getRepoRoot(): string {
  return findRepoRoot() || '/app'
}
