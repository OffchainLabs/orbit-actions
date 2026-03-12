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
  const envPath = path.join(repoRoot ?? process.cwd(), '.env')
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath })
  }
}

export function requireEnv(name: string): string {
  const value = process.env[name]
  if (!value) {
    die(`Required env var not set: ${name} (check your .env file)`)
  }
  return value
}

export function getScriptsDir(): string {
  const repoRoot = findRepoRoot()
  if (repoRoot) {
    return path.join(repoRoot, 'scripts', 'foundry')
  }
  return '/app/scripts/foundry'
}

export function getRepoRoot(): string {
  const root = findRepoRoot()
  if (root) return root
  console.warn('Could not find repo root, assuming /app')
  return '/app'
}
