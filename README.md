# blockchain-eng-template

A nice template repo that we can build to use for new projects. Maybe eventually for existing projects too

current setup:
- hardhat + ethers v6 + foundry
- solidity compiler config is synced between hardhat and foundry, with foundry.toml being the source

todo:
- nice libraries that leverage foundry’s fork cheatcodes to mock general cross chain interactions
- e2e testing setup with hardhat + test node
- default hardhat + foundry setup
- mutation testing
- other nice CI things like coverage etc.
- avoid having thousands of dependencies on publish to npm
- ...