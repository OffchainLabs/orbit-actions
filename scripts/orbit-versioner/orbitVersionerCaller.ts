import { main as orbitVersioner } from './orbitVersioner'

export function isJsonMode(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.JSON_OUTPUT?.toLowerCase() === 'true'
}

export async function runOrbitVersionerCaller({
  env = process.env,
}: {
  env?: NodeJS.ProcessEnv
} = {}): Promise<void> {
  if (!isJsonMode(env)) {
    await orbitVersioner()
    return
  }

  const originalConsoleLog = console.log

  try {
    console.log = () => undefined
    process.stdout.write(`${JSON.stringify(await orbitVersioner())}\n`)
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    process.stderr.write(`${JSON.stringify({ error: message })}\n`)
    throw error
  } finally {
    console.log = originalConsoleLog
  }
}

runOrbitVersionerCaller()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
  })
