# blockchain-eng-template

A nice template repo that we can build to use for new projects. Maybe eventually for existing projects too

current setup:
- hardhat + ethers v6 + foundry
- solidity compiler config is synced between hardhat and foundry, with foundry.toml being the source
- use the sdk's formatting options for ts, js, json, md files. use the forge formatter for sol files.
- CI
    - lint
    - unit tests (non fork, non integration)
    - contract size
    - foundry gas snapshot
    - check signatures
    - check storage

todo:
- nice libraries that leverage foundry’s fork cheatcodes to mock general cross chain interactions (probably done best as a separate project)
- e2e testing setup with hardhat + test node
- default hardhat + foundry setup
- mutation testing
- avoid having thousands of dependencies on publish to npm
- ...
