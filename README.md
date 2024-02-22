# blockchain-eng-template

A template repo that we can use for new projects. Maybe eventually for existing projects too

current setup:
- hardhat + ethers v6 + foundry
- solidity compiler config is synced between hardhat and foundry, with foundry.toml being the source
- use the sdk's formatting options for ts, js, json, md files. use the forge formatter for sol files.
- `yarn minimal-publish` script to generate a minimal `package.json` and `hardhat.config.js` before publishing to npm
- CI
    - audit-ci
    - lint
    - unit tests
    - fork tests
    - contract size
    - foundry gas snapshot
    - check signatures and storage (skips abstract contracts and interfaces, but this is easily changed in `scripts/print-contracts.bash`)
    - e2e testing with hardhat + test node. always spins up an L3, one job uses ETH fees, one uses custom fees

disabling features:
- e2e tests
    - comment out or delete the `test-e2e` and `test-e2e-custom-fee` jobs in `.github/workflows/build-test.yml`
    - optionally delete `test/e2e/`
- fork tests
    - comment out or delete the `test-fork` job in `build-test.yml`
    - optionally delete `test/fork`

todo / wishlist:
- license?
- nice libraries that leverage foundry’s fork cheatcodes to mock general cross chain interactions (probably done best as a separate project)
- default hardhat + foundry setup
- mutation testing
- slither / other static analysis
- https://github.com/OffchainLabs/nitro-contracts/pull/128/files
- general proxy upgrade safety
- ...
