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

const HELP_TEXT = `Usage: [path] [args...]

Browse and execute scripts from the foundry scripts directory.

Browsing:
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

Commands can be chained (e.g. deploy && execute). The execute step
automatically reads the deployed address from the broadcast output.
Set UPGRADE_ACTION_ADDRESS in .env to override (e.g. for multisig flows).

Forge behavior (broadcast, auth, verbosity, etc.) is configured via
FOUNDRY_* / ETH_* env vars in your .env file. See env templates for examples.`

function listDirectory(dir: string): void {
  const scriptsDir = getScriptsDir()
  let relPath = path.relative(scriptsDir, dir)
  if (relPath === '.') relPath = ''

  const isVersionDir = /^contract-upgrades\/[0-9]/.test(relPath)
  const isArbosDir = relPath === 'arbos-upgrades/at-timestamp'
  const isCategoryDir = /^[^/]+$/.test(relPath) && relPath !== ''

  if (isCategoryDir) {
    console.log('Browse deeper to see available scripts and commands.')
  } else if (isVersionDir || isArbosDir) {
    const hasEnvTemplates = fs.existsSync(path.join(dir, 'env-templates'))
    if (hasEnvTemplates) {
      console.log('Configure .env before running. See env-templates/ for examples.')
    } else {
      console.log('Configure .env before running. See the README for details.')
    }
  }
  console.log('')

  const contents = fs.readdirSync(dir)
  for (const item of contents) {
    if (!item.startsWith('.')) {
      console.log(`  ${item}`)
    }
  }

  if (isCategoryDir) {
    console.log('')
    console.log(`Example: ${relPath}/${contents.find(c => !c.startsWith('.')) ?? '<version>'}`)
  } else if (isVersionDir) {
    console.log('')
    console.log('Commands:')
    console.log(`  ${relPath}/deploy`)
    console.log(`  ${relPath}/execute`)
    console.log(`  ${relPath}/verify`)
  } else if (isArbosDir) {
    console.log('')
    console.log('Commands:')
    console.log(`  ${relPath}/deploy <version>`)
    console.log(`  ${relPath}/execute`)
    console.log(`  ${relPath}/verify`)
  }
}

export async function router(
  pathArg?: string,
  args: string[] = []
): Promise<void> {
  const scriptsDir = getScriptsDir()

  if (!pathArg) {
    console.log('orbit-actions - CLI for Orbit chain upgrade actions')
    console.log('')
    console.log('Browse and run upgrade scripts for Orbit chains. Configuration')
    console.log('is read from .env in the project root. Forge behavior (broadcast,')
    console.log('auth, verbosity) is controlled via FOUNDRY_* / ETH_* env vars.')
    console.log('')
    console.log('Available:')
    const contents = fs.readdirSync(scriptsDir)
    for (const item of contents) {
      if (!item.startsWith('.')) {
        console.log(`  ${item}/`)
      }
    }
    console.log('')
    console.log('Usage:')
    console.log('  <path>           Browse scripts')
    console.log('  <path>/deploy    Run a script')
    console.log('  help             Full usage details')
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
