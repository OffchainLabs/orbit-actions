export interface DeployExecuteAuth {
  deployKey: string;
  deployAccount: string;
  deployLedger: boolean;
  deployInteractive: boolean;
  executeKey: string;
  executeAccount: string;
  executeLedger: boolean;
  executeInteractive: boolean;
  dryRun: boolean;
  skipExecute: boolean;
  verifyContracts: boolean;
}

export function parseAuthArgs(args: string[]): string {
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--private-key' || arg === '--account') {
      const value = args[i + 1];
      if (value) {
        return `${arg} ${value}`;
      }
    }
    if (arg === '--ledger' || arg === '--interactive') {
      return arg;
    }
  }
  return '';
}

export function getDeployAuth(auth: DeployExecuteAuth): string {
  if (auth.deployKey) {
    return `--private-key ${auth.deployKey}`;
  }
  if (auth.deployAccount) {
    return `--account ${auth.deployAccount}`;
  }
  if (auth.deployLedger) {
    return '--ledger';
  }
  if (auth.deployInteractive) {
    return '--interactive';
  }
  return '';
}

export function getExecuteAuth(auth: DeployExecuteAuth): string {
  if (auth.executeKey) {
    return `--private-key ${auth.executeKey}`;
  }
  if (auth.executeAccount) {
    return `--account ${auth.executeAccount}`;
  }
  if (auth.executeLedger) {
    return '--ledger';
  }
  if (auth.executeInteractive) {
    return '--interactive';
  }
  return '';
}

export function createDeployExecuteAuth(options: {
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
}): DeployExecuteAuth {
  return {
    deployKey: options.deployKey || '',
    deployAccount: options.deployAccount || '',
    deployLedger: options.deployLedger || false,
    deployInteractive: options.deployInteractive || false,
    executeKey: options.executeKey || '',
    executeAccount: options.executeAccount || '',
    executeLedger: options.executeLedger || false,
    executeInteractive: options.executeInteractive || false,
    dryRun: options.dryRun || false,
    skipExecute: options.skipExecute || false,
    verifyContracts: options.verify || false,
  };
}
