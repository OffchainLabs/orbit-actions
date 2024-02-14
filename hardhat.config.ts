import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-foundry'

import { SolidityUserConfig } from 'hardhat/types'
import toml from 'toml'
import fs from 'fs'

const config: HardhatUserConfig = {
  solidity: getSolidityConfigFromFoundryToml(
    process.env.FOUNDRY_PROFILE || 'default'
  ),
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
