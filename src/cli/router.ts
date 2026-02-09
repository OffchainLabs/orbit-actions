import * as fs from 'fs';
import * as path from 'path';
import { die } from './utils/log';
import { getScriptsDir } from './utils/env';
import {
  cmdDeploy as contractDeploy,
  cmdExecute as contractExecute,
  cmdVerify as contractVerify,
  cmdDeployExecuteVerify as contractDeployExecuteVerify,
} from './commands/contract-upgrade';
import {
  cmdDeploy as arbosDeploy,
  cmdExecute as arbosExecute,
  cmdVerify as arbosVerify,
  cmdDeployExecuteVerify as arbosDeployExecuteVerify,
} from './commands/arbos-upgrade';

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
  contract-upgrades/<version>/deploy [--private-key KEY]
  contract-upgrades/<version>/execute [--private-key KEY]
  contract-upgrades/<version>/verify
  contract-upgrades/<version>/deploy-execute-verify [--deploy-key KEY] [--execute-key KEY]

  arbos-upgrades/at-timestamp/deploy <arbos-version> [--private-key KEY]
  arbos-upgrades/at-timestamp/execute [--private-key KEY]
  arbos-upgrades/at-timestamp/verify
  arbos-upgrades/at-timestamp/deploy-execute-verify <arbos-version> [--deploy-key KEY] [--execute-key KEY]

Options for deploy-execute-verify:
  --deploy-key KEY          Private key for deploy step
  --deploy-account NAME     Keystore account for deploy
  --deploy-ledger           Use Ledger for deploy
  --execute-key KEY         Private key for execute step
  --execute-account NAME    Keystore account for execute
  --execute-ledger          Use Ledger for execute
  --dry-run, -n             Simulate without broadcasting
  --skip-execute            Deploy only
  --verify, -v              Verify on block explorer

Examples:
  docker run orbit-actions contract-upgrades/1.2.1
  docker run orbit-actions contract-upgrades/1.2.1/README.md
  docker run -v $(pwd)/.env:/app/.env orbit-actions contract-upgrades/1.2.1/deploy-execute-verify --dry-run`;

function listDirectory(dir: string): void {
  const scriptsDir = getScriptsDir();
  let relPath = path.relative(scriptsDir, dir);
  if (relPath === '.') relPath = '';

  const contents = fs.readdirSync(dir);
  for (const item of contents) {
    if (!item.startsWith('.')) {
      console.log(item);
    }
  }

  if (/^contract-upgrades\/[0-9]/.test(relPath)) {
    console.log('---');
    console.log('deploy                 (run Deploy script)');
    console.log('execute                (run Execute script)');
    console.log('verify                 (run Verify script)');
    console.log('deploy-execute-verify  (full upgrade flow)');
  } else if (relPath === 'arbos-upgrades/at-timestamp') {
    console.log('---');
    console.log('deploy <version>                 (run Deploy script)');
    console.log('execute                          (execute upgrade action)');
    console.log('verify                           (check upgrade status)');
    console.log('deploy-execute-verify <version>  (full upgrade flow)');
  }
}

function parseOptions(args: string[]): Record<string, string | boolean> {
  const options: Record<string, string | boolean> = {};
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--deploy-key' || arg === '--execute-key' || arg === '--deploy-account' || arg === '--execute-account') {
      options[arg.replace(/^--/, '').replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = args[++i] || '';
    } else if (arg === '--deploy-ledger') {
      options.deployLedger = true;
    } else if (arg === '--execute-ledger') {
      options.executeLedger = true;
    } else if (arg === '--deploy-interactive') {
      options.deployInteractive = true;
    } else if (arg === '--execute-interactive') {
      options.executeInteractive = true;
    } else if (arg === '--dry-run' || arg === '-n') {
      options.dryRun = true;
    } else if (arg === '--skip-execute') {
      options.skipExecute = true;
    } else if (arg === '--verify' || arg === '-v') {
      options.verify = true;
    } else if (arg === '--private-key') {
      options.privateKey = args[++i] || '';
    } else if (arg === '--account') {
      options.account = args[++i] || '';
    } else if (arg === '--ledger') {
      options.ledger = true;
    } else if (arg === '--interactive') {
      options.interactive = true;
    }
  }
  return options;
}

export async function router(pathArg?: string, args: string[] = []): Promise<void> {
  const scriptsDir = getScriptsDir();

  if (!pathArg) {
    const contents = fs.readdirSync(scriptsDir);
    for (const item of contents) {
      if (!item.startsWith('.')) {
        console.log(item);
      }
    }
    return;
  }

  if (pathArg === 'help' || pathArg === '--help' || pathArg === '-h') {
    console.log(HELP_TEXT);
    return;
  }

  const fullPath = path.join(scriptsDir, pathArg);
  const parentPath = path.dirname(fullPath);
  const basename = path.basename(pathArg);

  if (!fs.existsSync(fullPath) && fs.existsSync(parentPath)) {
    const relParent = path.relative(scriptsDir, parentPath);

    if (/^contract-upgrades\/[0-9]/.test(relParent)) {
      const version = path.basename(relParent);
      const options = parseOptions(args);

      switch (basename) {
        case 'deploy':
          await contractDeploy(version, args);
          return;
        case 'execute':
          await contractExecute(version, args);
          return;
        case 'verify':
          await contractVerify(version);
          return;
        case 'deploy-execute-verify':
          await contractDeployExecuteVerify(version, options);
          return;
      }
    }

    if (relParent === 'arbos-upgrades/at-timestamp') {
      switch (basename) {
        case 'deploy':
        case 'deploy-execute-verify': {
          const version = args[0];
          if (!version) {
            console.error(`Error: ArbOS version required`);
            console.error(`Usage: arbos-upgrades/at-timestamp/${basename} <version> [options]`);
            process.exit(1);
          }
          const restArgs = args.slice(1);
          const restOptions = parseOptions(restArgs);
          if (basename === 'deploy') {
            await arbosDeploy(version, restArgs);
          } else {
            await arbosDeployExecuteVerify(version, restOptions);
          }
          return;
        }
        case 'execute':
          await arbosExecute(args);
          return;
        case 'verify':
          await arbosVerify();
          return;
      }
    }
  }

  if (fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory()) {
    listDirectory(fullPath);
    return;
  }

  if (fs.existsSync(fullPath) && fs.statSync(fullPath).isFile()) {
    const content = fs.readFileSync(fullPath, 'utf-8');
    console.log(content);
    return;
  }

  die(`Not found: ${pathArg}

Use 'help' to see available commands.`);
}
