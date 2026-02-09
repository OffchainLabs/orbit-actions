/**
 * Environment variable utilities
 */

import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';
import { die } from './log';

/**
 * Find the repository root by looking for package.json
 */
function findRepoRoot(): string | null {
  let dir = __dirname;
  // Walk up from current file location
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, 'package.json'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

/**
 * Load .env file from:
 * 1. Current working directory
 * 2. Repository root
 * 3. /app/.env (Docker)
 */
export function loadEnv(): void {
  const candidates = [
    path.join(process.cwd(), '.env'),
    findRepoRoot() ? path.join(findRepoRoot()!, '.env') : null,
    '/app/.env',
  ].filter((p): p is string => p !== null);

  for (const envPath of candidates) {
    if (fs.existsSync(envPath)) {
      dotenv.config({ path: envPath });
      return;
    }
  }
}

/**
 * Require an environment variable to be set
 * @throws Exits process if variable is not set
 */
export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    die(`Required env var not set: ${name} (check your .env file)`);
  }
  return value;
}

/**
 * Get an optional environment variable
 */
export function getEnv(name: string): string | undefined {
  return process.env[name];
}

/**
 * Get the scripts directory path
 */
export function getScriptsDir(): string {
  const repoRoot = findRepoRoot();
  if (repoRoot) {
    return path.join(repoRoot, 'scripts', 'foundry');
  }
  // Fallback for Docker
  return '/app/scripts/foundry';
}

/**
 * Get the repository root path
 */
export function getRepoRoot(): string {
  return findRepoRoot() || '/app';
}
