/**
 * Logging utilities for CLI
 */

const PREFIX = '[orbit-actions]';

/**
 * Log an informational message to stdout
 */
export function log(message: string): void {
  console.log(`${PREFIX} ${message}`);
}

/**
 * Log an error message and exit with code 1
 */
export function die(message: string): never {
  console.error(`Error: ${message}`);
  process.exit(1);
}
