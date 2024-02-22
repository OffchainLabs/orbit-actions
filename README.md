# blockchain-eng-template

A nice template repo that we can build to use for new projects. Maybe eventually for existing projects too

current setup:
- hardhat + ethers v6 + foundry
- solidity compiler config is synced between hardhat and foundry, with foundry.toml being the source
- use the sdk's formatting options for ts, js, json, md files. use the forge formatter for sol files.
- CI
    - lint
    - unit tests
    - fork tests
    - contract size
    - foundry gas snapshot
    - check signatures (skips abstract contracts and interfaces)
    - check storage (skips abstract contracts)
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
- yarn audit
- nice libraries that leverage foundry’s fork cheatcodes to mock general cross chain interactions (probably done best as a separate project)
- default hardhat + foundry setup
- mutation testing
- avoid having thousands of dependencies on publish to npm
- slither / other static analysis
- https://github.com/OffchainLabs/nitro-contracts/pull/128/files
- general proxy upgrade safety
- ...
