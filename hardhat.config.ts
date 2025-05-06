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
  etherscan: {
    apiKey: {
      baseSepolia: process.env['ETHERSCAN_API_KEY'],
    },
    customChains: [
      {
        network: 'nova',
        chainId: 42170,
        urls: {
          apiURL: 'https://api-nova.arbiscan.io/api',
          browserURL: 'https://nova.arbiscan.io/',
        },
      },
      {
        network: 'arbGoerliRollup',
        chainId: 421613,
        urls: {
          apiURL: 'https://api-goerli.arbiscan.io/api',
          browserURL: 'https://goerli.arbiscan.io/',
        },
      },
      {
        network: 'arbSepolia',
        chainId: 421614,
        urls: {
          apiURL: 'https://api-sepolia.arbiscan.io/api',
          browserURL: 'https://sepolia.arbiscan.io/',
        },
      },
      {
        network: 'baseSepolia',
        chainId: 84532,
        urls: {
          apiURL: 'https://api-sepolia.basescan.org/api',
          browserURL: 'https://sepolia.basescan.org/',
        },
      },
    ],
  },
  networks: {
    fork: {
      url: process.env.FORK_URL || 'http://localhost:8545',
    },
    arb1: {
      url: 'https://arb1.arbitrum.io/rpc',
    },
    base: {
      url:
        'https://base-mainnet.g.alchemy.com/v2/' +
        process.env['ALCHEMY_APIKEY'],
    },
    baseSepolia: {
      url:
        'https://base-sepolia.g.alchemy.com/v2/' +
        process.env['ALCHEMY_APIKEY'],
    },
    mainnet: {
      url:
        'https://eth-mainnet.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    sepolia: {
      url:
        'https://eth-sepolia.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    arbSepolia: {
      url:
        'https://arb-sepolia.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    421614: {
      url:
        'https://arb-sepolia.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    84532: {
      url:
        'https://base-sepolia.g.alchemy.com/v2/' +
        process.env['ALCHEMY_APIKEY'],
    },
    11155111: {
      url:
        'https://eth-sepolia.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    1: {
      url:
        'https://eth-mainnet.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    42161: {
      url:
        'https://arb-mainnet.g.alchemy.com/v2/' + process.env['ALCHEMY_APIKEY'],
    },
    8453: {
      url:
        'https://base-mainnet.g.alchemy.com/v2/' +
        process.env['ALCHEMY_APIKEY'],
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
