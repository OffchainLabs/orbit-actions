# Blockchain Eng Template Repo
## Current Setup
### Overview
- Hardhat + Ethers v6 + Foundry
- Solidity compiler config is synced between hardhat and foundry, with `foundry.toml` being the source
- Arbitrum SDK formatting config for `ts`, `js`, `json` files
- Forge formatter for `sol` files.
- `yarn minimal-publish` script to generate a minimal `package.json` and `hardhat.config.js` before publishing to npm
- CI
    - Audit
    - Lint
    - Unit tests
    - Fork tests
    - Contract size
    - Foundry gas snapshot
    - Check signatures and storage
    - E2E testing with Hardhat + Arbitrum SDK + testnode

### Compiler Settings
Compiler settings are defined in `foundry.toml` and are copied by `hardhat.config.ts`.

Settings other than optimizer runs or solc version ARE NOT copied by `hardhat.config.ts`. For example, Hardhat will not know if via-ir is set in `foundry.toml`.

### Fork Tests
Fork tests are located in `test/fork/<chain_name>/` and will run against the latest block of `$<CHAIN_NAME>_FORK_URL`.
Use `yarn test:fork`.

Test files should only be placed in `test/fork/<chain_name>/` (subdrectories are allowed).
Test files placed directly in `test/fork/` will not run.

`yarn test:fork` will pass if there are no test files.

To disable fork tests:
- Remove `.github/workflows/test-fork.yml` to disable in CI
- Remove the `test:fork` script from `package.json`
- Remove `test/fork`

### E2E Tests
End to end tests are located in `test/e2e/`, and ran by `yarn test:e2e`.

After starting a testnode instance, run `yarn gen:network` before `yarn test:e2e`.

The GitHub workflow defined in `.github/workflows/test-e2e.yml` will run test files against an L1+L2+L3 nitro testnode setup, once with an ETH fee L3 and once with a custom fee L3. 

It is recommended to use `testSetup` defined in `test/e2e/testSetup.ts` to get signers, providers, and network information. Note that there is also a `testSetup` function defined in the sdk, don't use that one.

This repository uses ethers v6, but the Arbitrum SDK uses ethers v5. 
A separate ethers v5 dev dependency is included and can be imported for use with the sdk.
```typescript
import { ethers as ethersv5 } from 'ethers-v5'
```

To disable E2E tests:
- Remove `.github/workflows/test-e2e.yml` to disable in CI
- Remove `test:e2e` and `gen:network` scripts from `package.json`
- Remove `test/e2e`

If E2E tests are disabled, the Arbitrum SDK dependency is likely no longer required. To remove it:
- `forge remove lib/arbitrum-sdk`
- Remove `prepare-sdk` script and modify the `prepare` script in `package.json`

### Signatures and Storage Tests
These will fail if signatures or storage of any contract defined in `contracts/` changes.

Abstract contracts and interfaces are not checked. `scripts/print-contracts.bash` produces the list of contracts that are checked in these tests.

Use `yarn test:signatures` and `yarn test:storage`.

### Publishing to NPM
A helper script, `minimal-publish` is included to generate a minimal `package.json` and `hardhat.config.js` before publishing to NPM.

`yarn minimal-publish` will:
- Generate a minimal `package.json` and `hardhat.config.js` from the existing `package.json` and solidity compiler settings
- Prompt the user to confirm these files
- Publish to NPM if the user confirms
- Restore original files
- Commit and tag if published successfully

Note that `yarn publish --non-interactive` is used, so there will be no prompt for package version. See `scripts/publish.bash`

## TODO / Wishlist
- license?
- nice libraries that leverage foundry’s fork cheatcodes to mock general cross chain interactions (probably done best as a separate project)
- mutation testing
- slither / other static analysis
- https://github.com/OffchainLabs/nitro-contracts/pull/128/files
- general proxy upgrade safety
- ...
