const PREFIX = '[orbit-actions]'

export function log(message: string): void {
  console.log(`${PREFIX} ${message}`)
}

export function die(message: string): never {
  console.error(`Error: ${message}`)
  process.exit(1)
}
