export function die(message: string): never {
  console.error(`Error: ${message}`)
  process.exit(1)
}
