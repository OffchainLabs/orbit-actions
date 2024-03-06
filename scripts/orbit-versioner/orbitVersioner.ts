import { ethers } from 'hardhat'
import metadataHashes from './referentMetadataHashes.json'
import { HardhatEthersProvider } from '@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider'
import {
  IBridge__factory,
  IInbox__factory,
  IRollupCore__factory,
} from '../../typechain-types'
import { abi as IERC20BridgeABI } from '@arbitrum/nitro-contracts-1.2.1/build/contracts/src/bridge/IERC20Bridge.sol/IERC20Bridge.json'

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
  })

/**
 * Interfaces
 */
interface ReferentMetadataHashes {
  Inbox: string[]
  Outbox: string[]
  SequencerInbox: string[]
  Bridge: string[]
}
interface MetadataHashesByNativeToken {
  eth: ReferentMetadataHashes
  erc20: ReferentMetadataHashes
}
interface MetadataHashesByVersion {
  [version: string]: MetadataHashesByNativeToken
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
  const outboxAddress = await IRollupCore__factory.connect(
    await bridge.rollup(),
    provider
  ).outbox()
  const isUsingFeeToken = await _isUsingFeeToken(bridgeAddress, provider)

  // get metadata hashes
  const metadataHashes: { [key: string]: string } = {
    Inbox: await _getMetadataHash(inboxAddress, provider),
    Outbox: await _getMetadataHash(outboxAddress, provider),
    SequencerInbox: await _getMetadataHash(seqInboxAddress, provider),
    Bridge: await _getMetadataHash(bridgeAddress, provider),
  }

  console.log('\nMetadataHashes of deployed contracts:', metadataHashes, '\n')

  // get and print version per bridge contract
  const nativeType = isUsingFeeToken ? 'erc20' : 'eth'
  Object.keys(metadataHashes).forEach(key => {
    const version = _getVersionOfDeployedContract(
      metadataHashes[key],
      nativeType,
      key as keyof ReferentMetadataHashes
    )
    console.log(`Version of deployed ${key}: ${version ? version : 'unknown'}`)
  })
}

function _getVersionOfDeployedContract(
  metadataHash: string,
  type: 'eth' | 'erc20',
  contractName: keyof ReferentMetadataHashes
): string | null {
  for (const [version] of Object.entries(referentMetadataHashes)) {
    if (
      referentMetadataHashes[version][type][contractName].includes(metadataHash)
    ) {
      return version
    }
  }
  return null
}

async function _getMetadataHash(
  contractAddress: string,
  provider: HardhatEthersProvider
): Promise<string> {
  const implAddress = await _getLogicAddress(contractAddress, provider)
  const bytecode = await provider.getCode(implAddress)

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

async function _isUsingFeeToken(
  bridgeAddress: string,
  provider: HardhatEthersProvider
): Promise<boolean> {
  const bridge = new ethers.Contract(bridgeAddress, IERC20BridgeABI, provider)
  try {
    const feeToken = await bridge.nativeToken()
    if (feeToken == ethers.ZeroAddress) {
      return false
    } else {
      return true
    }
  } catch {
    return false
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