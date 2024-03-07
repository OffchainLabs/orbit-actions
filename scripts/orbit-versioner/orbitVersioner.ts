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
  }

  console.log('\nMetadataHashes of deployed contracts:', metadataHashes, '\n')

  // get and print version per bridge contract
  Object.keys(metadataHashes).forEach(key => {
    const version = _getVersionOfDeployedContract(metadataHashes[key])
    console.log(`Version of deployed ${key}: ${version ? version : 'unknown'}`)
  })
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
