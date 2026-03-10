import * as fs from 'fs'
import * as path from 'path'
import { die } from './utils/log'
import { getScriptsDir } from './utils/env'
import {
  cmdDeploy as contractDeploy,
  cmdExecute as contractExecute,
  cmdVerify as contractVerify,
} from './commands/contract-upgrade'
import {
  cmdDeploy as arbosDeploy,
  cmdExecute as arbosExecute,
  cmdVerify as arbosVerify,
} from './commands/arbos-upgrade'

const HELP_TEXT = `Usage: orbit-actions [path] [args...]

Browse and execute scripts from the foundry scripts directory.

Browsing:
  .                                      List top-level directories
  contract-upgrades                      List available versions
  contract-upgrades/1.2.1                List version contents + commands
  contract-upgrades/1.2.1/env-templates  List env templates

Viewing files:
  contract-upgrades/1.2.1/README.md                     View README
  contract-upgrades/1.2.1/env-templates/.env.example    View env template
  contract-upgrades/2.1.0/.env.sample                   View env sample

Running upgrade scripts:
  contract-upgrades/<version>/deploy
  contract-upgrades/<version>/execute
  contract-upgrades/<version>/verify

  arbos-upgrades/at-timestamp/deploy <arbos-version>
  arbos-upgrades/at-timestamp/execute
  arbos-upgrades/at-timestamp/verify

Forge behavior (broadcast, auth, verbosity, etc.) is configured via
FOUNDRY_* / ETH_* env vars in your .env file. See env templates for examples.

Examples:
  docker run orbit-actions contract-upgrades/1.2.1
  docker run orbit-actions contract-upgrades/1.2.1/README.md
  docker run -v $(pwd)/.env:/app/.env orbit-actions contract-upgrades/1.2.1/deploy
  docker run -v $(pwd)/.env:/app/.env orbit-actions contract-upgrades/1.2.1/execute`

function listDirectory(dir: string): void {
  const scriptsDir = getScriptsDir()
  let relPath = path.relative(scriptsDir, dir)
  if (relPath === '.') relPath = ''

  const contents = fs.readdirSync(dir)
  for (const item of contents) {
    if (!item.startsWith('.')) {
      console.log(item)
    }
  }

  if (/^contract-upgrades\/[0-9]/.test(relPath)) {
    console.log('---')
    console.log('deploy   (run Deploy script)')
    console.log('execute  (run Execute script)')
    console.log('verify   (run Verify script)')
  } else if (relPath === 'arbos-upgrades/at-timestamp') {
    console.log('---')
    console.log('deploy <version>  (run Deploy script)')
    console.log('execute           (execute upgrade action)')
    console.log('verify            (check upgrade status)')
  }
}

export async function router(
  pathArg?: string,
  args: string[] = []
): Promise<void> {
  const scriptsDir = getScriptsDir()

  if (!pathArg) {
    const contents = fs.readdirSync(scriptsDir)
    for (const item of contents) {
      if (!item.startsWith('.')) {
        console.log(item)
      }
    }
    return
  }

  if (pathArg === 'help' || pathArg === '--help' || pathArg === '-h') {
    console.log(HELP_TEXT)
    return
  }

  const fullPath = path.join(scriptsDir, pathArg)
  const parentPath = path.dirname(fullPath)
  const basename = path.basename(pathArg)

  if (!fs.existsSync(fullPath) && fs.existsSync(parentPath)) {
    const relParent = path.relative(scriptsDir, parentPath)

    if (/^contract-upgrades\/[0-9]/.test(relParent)) {
      const version = path.basename(relParent)

      switch (basename) {
        case 'deploy':
          await contractDeploy(version)
          return
        case 'execute':
          await contractExecute(version)
          return
        case 'verify':
          await contractVerify(version)
          return
      }
    }

    if (relParent === 'arbos-upgrades/at-timestamp') {
      switch (basename) {
        case 'deploy': {
          const version = args[0]
          if (!version) {
            die(
              'ArbOS version required\nUsage: arbos-upgrades/at-timestamp/deploy <version>'
            )
          }
          await arbosDeploy(version)
          return
        }
        case 'execute':
          await arbosExecute()
          return
        case 'verify':
          await arbosVerify()
          return
      }
    }
  }

  if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
    listDirectory(fullPath)
    return
  }

  if (fs.existsSync(fullPath) && fs.statSync(fullPath).isFile()) {
    const content = fs.readFileSync(fullPath, 'utf-8')
    console.log(content)
    return
  }

  die(`Not found: ${pathArg}

Use 'help' to see available commands.`)
}
