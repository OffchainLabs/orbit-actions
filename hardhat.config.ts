import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-foundry'
import dotenv from 'dotenv'
dotenv.config()

import { SolidityUserConfig } from 'hardhat/types'
import toml from 'toml'
import fs from 'fs'

const config: HardhatUserConfig = {
  solidity: getSolidityConfigFromFoundryToml(
    process.env.FOUNDRY_PROFILE || 'default'
  ),
  networks: {
    fork: {
      url: process.env.FORK_URL || 'http://localhost:8545',
    },
    arb1: {
      url: 'https://arb1.arbitrum.io/rpc',
    },
    base: {
      url: 'https://base-mainnet.g.alchemy.com/v2/8I7-qkB146nw-z1yFOnVB3vkzlbg78hN',
    },
    baseSepolia: {
      url: 'https://base-sepolia.g.alchemy.com/v2/8I7-qkB146nw-z1yFOnVB3vkzlbg78hN',
    },
    mainnet: {
      url: 'https://eth-mainnet.g.alchemy.com/v2/vptzjr-B0MGFskb9rh6G8AtzK4dWUzLA',
    },
    sepolia: {
      url: 'https://eth-sepolia.g.alchemy.com/v2/fpQPC7q22cy7i2rILZBCiibBXQkjpwJO',
    },
    arbSepolia: {
      url: 'https://nd-547-613-041.p2pify.com/909153f12fbb522c2703d4b5b55a78a5',
    },
    nova: {
      url: 'https://nova.arbitrum.io/rpc',
    },
    holesky: {
      url: 'https://1rpc.io/holesky',
    },
  },
}

function getSolidityConfigFromFoundryToml(profile: string): SolidityUserConfig {
  const data = toml.parse(fs.readFileSync('foundry.toml', 'utf-8'))

  const defaultConfig = data.profile['default']
  const profileConfig = data.profile[profile || 'default']

  const solidity = {
    version: profileConfig?.solc_version || defaultConfig.solc_version,
    settings: {
      optimizer: {
        enabled: true,
        runs: profileConfig?.optimizer_runs || defaultConfig.optimizer_runs,
      },
    },
  }

  return solidity
}

export default config
