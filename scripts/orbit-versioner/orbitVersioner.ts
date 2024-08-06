import { ethers } from 'hardhat'
import metadataHashes from './referentMetadataHashes.json'
import { HardhatEthersProvider } from '@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider'
import {
  IBridge__factory,
  IInbox__factory,
  IRollupCore__factory,
} from '../../typechain-types'

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
  })

/**
 * Interfaces
 */
interface BridgeHashes {
  Inbox: string[]
  Outbox: string[]
  SequencerInbox: string[]
  Bridge: string[]
}
interface MetadataHashesByNativeToken {
  eth: BridgeHashes
  erc20: BridgeHashes
}
interface RollupHashes {
  RollupProxy: string[]
  RollupAdminLogic: string[]
  RollupUserLogic: string[]
  ChallengeManager: string[]
}
interface MetadataHashesByVersion {
  [version: string]: MetadataHashesByNativeToken & RollupHashes
}

/**
 * Load the referent metadata hashes
 */

const referentMetadataHashes: MetadataHashesByVersion = metadataHashes

/**
 * Script will
 */
async function main() {
  if (!process.env.INBOX_ADDRESS) {
    throw new Error('INBOX_ADDRESS env variable shall be set')
  }

  /// get provider
  const provider = ethers.provider
  const chainId = (await provider.getNetwork()).chainId
  const inboxAddress = process.env.INBOX_ADDRESS!

  console.log(
    `Get the version of Orbit chain's nitro contracts (inbox ${inboxAddress}), hosted on chain ${chainId}`
  )

  // get all core addresses from inbox address
  const inbox = IInbox__factory.connect(inboxAddress, provider)
  const bridgeAddress = await inbox.bridge()
  const bridge = IBridge__factory.connect(bridgeAddress, provider)
  const seqInboxAddress = await bridge.sequencerInbox()
  const rollupAddress = await bridge.rollup()
  const outboxAddress = await IRollupCore__factory.connect(
    rollupAddress,
    provider
  ).outbox()
  const challengeManagerAddress = await IRollupCore__factory.connect(
    rollupAddress,
    provider
  ).challengeManager()

  // get metadata hashes
  const metadataHashes: { [key: string]: string } = {
    Inbox: await _getMetadataHash(
      await _getLogicAddress(inboxAddress, provider),
      provider
    ),
    Outbox: await _getMetadataHash(
      await _getLogicAddress(outboxAddress, provider),
      provider
    ),
    SequencerInbox: await _getMetadataHash(
      await _getLogicAddress(seqInboxAddress, provider),
      provider
    ),
    Bridge: await _getMetadataHash(
      await _getLogicAddress(bridgeAddress, provider),
      provider
    ),
    RollupProxy: await _getMetadataHash(rollupAddress, provider),
    RollupAdminLogic: await _getMetadataHash(
      await _getLogicAddress(rollupAddress, provider),
      provider
    ),
    RollupUserLogic: await _getMetadataHash(
      await _getAddressAtStorageSlot(
        rollupAddress,
        provider,
        '0x2b1dbce74324248c222f0ec2d5ed7bd323cfc425b336f0253c5ccfda7265546d'
      ),
      provider
    ),
    ChallengeManager: await _getMetadataHash(
      await _getLogicAddress(challengeManagerAddress, provider),
      provider
    ),
  }

  if (process.env.DEV === 'true') {
    console.log('\nMetadataHashes of deployed contracts:', metadataHashes, '\n')
  }

  const versions: { [key: string]: string | null } = {}
  // get and print version per bridge contract
  Object.keys(metadataHashes).forEach(key => {
    versions[key] = _getVersionOfDeployedContract(metadataHashes[key])
    console.log(
      `Version of deployed ${key}: ${versions[key] ? versions[key] : 'unknown'}`
    )
  })

  // TODO: make this more generic to support other other upgrade paths in the future
  // TODO: also check  osp
  _checkForPossibleUpgrades(versions)
}

function _checkForPossibleUpgrades(currentVersions: {
  [key: string]: string | null
}) {
  const targetVersionsDescending = [
    {
      version: 'v2.1.0',
      actionName: 'NitroContracts2Point1Point0UpgradeAction',
    },
    {
      version: 'v1.2.1',
      actionName: 'NitroContracts1Point2Point1UpgradeAction',
    },
  ]

  for (const target of targetVersionsDescending) {
    if (_canBeUpgradedToTargetVersion(target.version, currentVersions)) {
      console.log(
        `This deployment can be upgraded to ${target.version} using ${target.actionName}`
      )
      return
    }
  }

  console.log('No upgrade path found')
}

function _canBeUpgradedToTargetVersion(
  targetVersion: string,
  currentVersions: {
    [key: string]: string | null
  }
): boolean {
  console.log('\nChecking if deployment can be upgraded to', targetVersion)

  let supportedSourceVersionsPerContract: { [key: string]: string[] } = {}
  if (targetVersion === 'v2.1.0') {
    supportedSourceVersionsPerContract = {
      Inbox: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      Outbox: [
        'v1.1.0',
        'v1.1.1',
        'v1.2.0',
        'v1.2.1',
        'v1.3.0',
        'v2.0.0',
        'v2.1.0',
      ],
      Bridge: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      RollupProxy: [
        'v1.1.0',
        'v1.1.1',
        'v1.2.0',
        'v1.2.1',
        'v1.3.0',
        'v2.0.0',
        'v2.1.0',
      ],
      RollupAdminLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      RollupUserLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      ChallengeManager: ['v1.2.1', 'v1.3.0'],
      SequencerInbox: ['v1.2.1', 'v1.3.0', 'v2.0.0', 'v2.1.0'],
    }
  } else if (targetVersion === 'v1.2.1') {
    supportedSourceVersionsPerContract = {
      Inbox: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      Outbox: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      Bridge: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      RollupProxy: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      RollupAdminLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      RollupUserLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      ChallengeManager: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      SequencerInbox: ['v1.1.0', 'v1.1.1'],
    }
  } else {
    console.log('Unsupported target version')
    return false
  }

  // check if all contracts can be upgraded to target version
  for (const [contract, supportedSourceVersions] of Object.entries(
    supportedSourceVersionsPerContract
  )) {
    if (!supportedSourceVersions.includes(currentVersions[contract]!)) {
      // found contract that can't be upgraded to target version
      console.log('Cannot upgrade', contract, 'to', targetVersion)
      return false
    }
  }
  // all contracts can be upgraded to target version
  return true
}

function _getVersionOfDeployedContract(metadataHash: string): string | null {
  for (const [version] of Object.entries(referentMetadataHashes)) {
    // check if given hash matches any of the referent hashes for specific version
    const versionHashes = referentMetadataHashes[version]
    const allHashes = [
      ...Object.values(versionHashes.eth).flat(),
      ...Object.values(versionHashes.erc20).flat(),
      ...versionHashes.RollupProxy,
      ...versionHashes.RollupAdminLogic,
      ...versionHashes.RollupUserLogic,
      ...versionHashes.ChallengeManager,
    ]

    if (allHashes.includes(metadataHash)) {
      return version
    }
  }
  return null
}

async function _getMetadataHash(
  contractAddress: string,
  provider: HardhatEthersProvider
): Promise<string> {
  const bytecode = await provider.getCode(contractAddress)

  // Pattern to match the metadata prefix and the following 64 hex characters (32 bytes)
  const metadataPattern = /a264697066735822([a-fA-F0-9]{64})/
  const matches = bytecode.match(metadataPattern)

  if (matches && matches.length > 1) {
    // The actual metadata hash is in the first capturing group
    return matches[1]
  } else {
    throw new Error('No metadata hash found in bytecode')
  }
}

async function _getLogicAddress(
  contractAddress: string,
  provider: HardhatEthersProvider
): Promise<string> {
  const logic = (
    await _getAddressAtStorageSlot(
      contractAddress,
      provider,
      '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc'
    )
  ).toLowerCase()

  if (logic == '' || logic == ethers.ZeroAddress) {
    return contractAddress
  }

  return logic
}

async function _getAddressAtStorageSlot(
  contractAddress: string,
  provider: HardhatEthersProvider,
  storageSlotBytes: string
): Promise<string> {
  const storageValue = await provider.getStorage(
    contractAddress,
    storageSlotBytes
  )

  if (!storageValue) {
    return ''
  }

  // remove excess bytes
  const formatAddress =
    storageValue.substring(0, 2) + storageValue.substring(26)

  // return address as checksum address
  return ethers.getAddress(formatAddress)
}
