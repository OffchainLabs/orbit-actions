import { Command } from 'commander';
import * as path from 'path';
import * as fs from 'fs';
import { log, die } from '../utils/log';
import { requireEnv, getEnv, getScriptsDir } from '../utils/env';
import { parseAuthArgs, createDeployExecuteAuth, getDeployAuth, getExecuteAuth } from '../utils/auth';
import { runForgeScript, getChainId, parseActionAddress, findScript } from '../utils/forge';

const CONTRACTS_DIR = path.join(getScriptsDir(), 'contract-upgrades');

function getVersionDir(version: string): string {
  const versionDir = path.join(CONTRACTS_DIR, version);
  if (!fs.existsSync(versionDir)) {
    const available = fs.existsSync(CONTRACTS_DIR)
      ? fs.readdirSync(CONTRACTS_DIR).filter((f) => !f.startsWith('.')).join(' ')
      : 'none found';
    die(`Unknown version: ${version}\n\nAvailable versions: ${available}`);
  }
  return versionDir;
}

async function cmdDeploy(version: string, args: string[]): Promise<void> {
  const versionDir = getVersionDir(version);
  const authArgs = parseAuthArgs(args);

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC');

  const deployScript = findScript(versionDir, /^Deploy.*\.s\.sol$/);
  if (!deployScript) {
    die(`No deploy script found in ${versionDir}`);
  }

  log(`Running: ${path.basename(deployScript)}`);

  await runForgeScript({
    script: deployScript,
    rpcUrl,
    authArgs,
    broadcast: !!authArgs,
    slow: true,
    skipSimulation: true,
  });
}

async function cmdExecute(version: string, args: string[]): Promise<void> {
  const versionDir = getVersionDir(version);
  const authArgs = parseAuthArgs(args);

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC');
  requireEnv('UPGRADE_ACTION_ADDRESS');

  const executeScript = findScript(versionDir, /^Execute.*\.s\.sol$/);
  if (!executeScript) {
    die(`No execute script found in ${versionDir}`);
  }

  log(`Running: ${path.basename(executeScript)}`);

  await runForgeScript({
    script: executeScript,
    rpcUrl,
    authArgs,
    broadcast: !!authArgs,
  });
}

async function cmdVerify(version: string): Promise<void> {
  const versionDir = getVersionDir(version);

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC');

  const verifyScript = findScript(versionDir, /^Verify.*\.s\.sol$/);
  if (!verifyScript) {
    die(`No verify script found in ${versionDir} - check README for manual verification`);
  }

  log(`Running: ${path.basename(verifyScript)}`);

  await runForgeScript({
    script: verifyScript,
    rpcUrl,
  });
}

async function cmdDeployExecuteVerify(
  version: string,
  options: {
    deployKey?: string;
    deployAccount?: string;
    deployLedger?: boolean;
    deployInteractive?: boolean;
    executeKey?: string;
    executeAccount?: string;
    executeLedger?: boolean;
    executeInteractive?: boolean;
    dryRun?: boolean;
    skipExecute?: boolean;
    verify?: boolean;
  }
): Promise<void> {
  const versionDir = getVersionDir(version);
  const auth = createDeployExecuteAuth(options);

  const deployScript = findScript(versionDir, /^Deploy.*\.s\.sol$/);
  const executeScript = findScript(versionDir, /^Execute.*\.s\.sol$/);

  if (!deployScript) {
    die(`No deploy script found in ${versionDir}`);
  }
  if (!executeScript) {
    die(`No execute script found in ${versionDir}`);
  }

  log(`Version: ${version}`);
  log(`Deploy script: ${path.basename(deployScript)}`);
  log(`Execute script: ${path.basename(executeScript)}`);

  // Auto-detect skip_deploy if UPGRADE_ACTION_ADDRESS is set
  let skipDeploy = !!getEnv('UPGRADE_ACTION_ADDRESS');
  let upgradeActionAddress = getEnv('UPGRADE_ACTION_ADDRESS') || '';

  if (skipDeploy) {
    log(`Using existing action from .env: ${upgradeActionAddress}`);
  }

  const rpcUrl = requireEnv('PARENT_CHAIN_RPC');
  requireEnv('INBOX_ADDRESS');
  requireEnv('PROXY_ADMIN_ADDRESS');
  requireEnv('PARENT_UPGRADE_EXECUTOR_ADDRESS');

  const deployAuth = getDeployAuth(auth);
  const executeAuth = getExecuteAuth(auth);

  if (!skipDeploy && !auth.dryRun && !deployAuth) {
    die('Deploy auth required. Use --deploy-key, --deploy-account, --deploy-ledger, or --deploy-interactive');
  }
  if (!auth.skipExecute && !auth.dryRun && !executeAuth) {
    die('Execute auth required. Use --execute-key, --execute-account, --execute-ledger, or --execute-interactive');
  }

  const chainId = await getChainId(rpcUrl);
  log(`Target chain ID: ${chainId}`);

  if (!skipDeploy) {
    log('Step 1: Deploying upgrade action...');

    await runForgeScript({
      script: deployScript,
      rpcUrl,
      authArgs: deployAuth,
      broadcast: !auth.dryRun,
      verify: auth.verifyContracts,
      slow: true,
      skipSimulation: true,
    });

    if (!auth.dryRun) {
      upgradeActionAddress = parseActionAddress(deployScript, chainId);
      log(`Deployed action at: ${upgradeActionAddress}`);
    } else {
      log('Dry run - no action deployed');
      if (!auth.skipExecute) {
        log('Note: Set UPGRADE_ACTION_ADDRESS in .env to run execute step');
        return;
      }
    }
  } else {
    log('Step 1: Skipped deploy');
  }

  // Forge script reads this from env
  process.env.UPGRADE_ACTION_ADDRESS = upgradeActionAddress;

  if (!auth.skipExecute) {
    log('Step 2: Executing upgrade...');

    await runForgeScript({
      script: executeScript,
      rpcUrl,
      authArgs: executeAuth,
      broadcast: !auth.dryRun,
    });

    if (auth.dryRun) {
      log('Dry run - upgrade not executed');
    } else {
      log('Upgrade executed successfully');
    }
  } else {
    log('Step 2: Skipped execute');
  }

  if (!auth.dryRun && !auth.skipExecute) {
    log('Step 3: Verifying upgrade...');

    const verifyScript = findScript(versionDir, /^Verify.*\.s\.sol$/);
    if (verifyScript) {
      await runForgeScript({
        script: verifyScript,
        rpcUrl,
      });
    } else {
      log('No Verify script found - check README for manual verification');
    }
  }

  log('Done');
}

export function createContractUpgradeCommand(): Command {
  const cmd = new Command('contract-upgrade')
    .description('Contract upgrade operations')
    .argument('<version>', 'Contract version (e.g., 1.2.1)')
    .argument('<command>', 'Command: deploy, execute, verify, deploy-execute-verify')
    .option('--private-key <key>', 'Private key (for deploy/execute)')
    .option('--account <name>', 'Keystore account (for deploy/execute)')
    .option('--ledger', 'Use Ledger (for deploy/execute)')
    .option('--interactive', 'Prompt for key (for deploy/execute)')
    .option('--deploy-key <key>', 'Private key for deploy step')
    .option('--deploy-account <name>', 'Keystore account for deploy')
    .option('--deploy-ledger', 'Use Ledger for deploy')
    .option('--deploy-interactive', 'Prompt for key for deploy')
    .option('--execute-key <key>', 'Private key for execute step')
    .option('--execute-account <name>', 'Keystore account for execute')
    .option('--execute-ledger', 'Use Ledger for execute')
    .option('--execute-interactive', 'Prompt for key for execute')
    .option('-n, --dry-run', 'Simulate without broadcasting')
    .option('--skip-execute', 'Deploy only')
    .option('-v, --verify', 'Verify on block explorer')
    .action(async (version: string, command: string, options) => {
      const args: string[] = [];
      if (options.privateKey) args.push('--private-key', options.privateKey);
      if (options.account) args.push('--account', options.account);
      if (options.ledger) args.push('--ledger');
      if (options.interactive) args.push('--interactive');

      switch (command) {
        case 'deploy':
          await cmdDeploy(version, args);
          break;
        case 'execute':
          await cmdExecute(version, args);
          break;
        case 'verify':
          await cmdVerify(version);
          break;
        case 'deploy-execute-verify':
          await cmdDeployExecuteVerify(version, options);
          break;
        default:
          die(`Unknown command: ${command}\n\nCommands: deploy, execute, verify, deploy-execute-verify`);
      }
    });

  return cmd;
}

export { cmdDeploy, cmdExecute, cmdVerify, cmdDeployExecuteVerify, getVersionDir };
