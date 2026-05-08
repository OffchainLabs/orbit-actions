import metadataHashes from './referentMetadataHashes.json'
import contractAddresses from './referentContractAddresses.json'
import {
  IBridge__factory,
  IInbox__factory,
  IRollupCore__factory,
} from '../../typechain-types'
import { ethers, JsonRpcProvider } from 'ethers'

const HELP_TEXT = `Usage: yarn chain:contracts:version [--help]

Reports the deployed Nitro contract versions for an Orbit chain and prints any
supported upgrade path.

Required environment variables:
  INBOX_ADDRESS     Address of the Orbit chain inbox on the parent chain
  PARENT_CHAIN_RPC  RPC URL for the Orbit chain's parent chain

Optional environment variables:
  JSON_OUTPUT       Set to "true" to print machine-readable JSON

Example:
  INBOX_ADDRESS=0x... PARENT_CHAIN_RPC=https://... yarn chain:contracts:version`

function createLogger(jsonOutput: boolean) {
  return (...args: unknown[]) => {
    if (!jsonOutput) {
      console.log(...args)
    }
  }
}

/**
 * Interfaces
 */
interface BridgeHashes {
  Inbox: string[]
  Outbox: string[]
  SequencerInbox: string[]
  Bridge: string[]
  RollupEventInbox: string[]
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

export interface UpgradePath {
  actionName: string
  targetVersion: string
  isRecommendedVersion: boolean
}
export interface UpgradeRecommendation {
  message: string
  upgradePaths?: UpgradePath[]
}

export interface OrbitVersionerReport {
  versions: { [key: string]: string | null }
  upgradeRecommendation: UpgradeRecommendation
}

export type ChainVersionerReport = OrbitVersionerReport

/**
 * Load the referent metadata hashes
 */
const referentMetadataHashes: MetadataHashesByVersion = metadataHashes
const referentContractAddresses: MetadataHashesByVersion = contractAddresses

/**
 * Script will
 */
export async function runChainVersioner(
  inboxAddress: string,
  parentRpcUrl: string,
  jsonOutput: boolean
): Promise<OrbitVersionerReport> {
  const log = createLogger(jsonOutput)

  /// get provider
  const provider = new ethers.JsonRpcProvider(parentRpcUrl)
  const chainId = (await provider.getNetwork()).chainId

  log(
    `Get the version of Orbit chain's nitro contracts (inbox ${inboxAddress}), hosted on chain ${chainId}`
  )

  // get all core addresses from inbox address
  const inbox = IInbox__factory.connect(inboxAddress, provider)
  const bridgeAddress = await inbox.bridge()
  const bridge = IBridge__factory.connect(bridgeAddress, provider)
  const seqInboxAddress = await bridge.sequencerInbox()
  const rollupAddress = await bridge.rollup()
  const rollup = IRollupCore__factory.connect(rollupAddress, provider)
  const outboxAddress = await rollup.outbox()
  const challengeManagerAddress = await rollup.challengeManager()
  const rollupEventInboxAddress = await rollup.rollupEventInbox()

  // get logic addresses for each contract
  const logicAddresses: { [key: string]: string } = {
    Inbox: await _getLogicAddress(inboxAddress, provider),
    Outbox: await _getLogicAddress(outboxAddress, provider),
    SequencerInbox: await _getLogicAddress(seqInboxAddress, provider),
    Bridge: await _getLogicAddress(bridgeAddress, provider),
    RollupEventInbox: await _getLogicAddress(rollupEventInboxAddress, provider),
    RollupProxy: rollupAddress,
    RollupAdminLogic: await _getLogicAddress(rollupAddress, provider),
    RollupUserLogic: await _getAddressAtStorageSlot(
      rollupAddress,
      provider,
      '0x2b1dbce74324248c222f0ec2d5ed7bd323cfc425b336f0253c5ccfda7265546d'
    ),
    ChallengeManager: await _getLogicAddress(challengeManagerAddress, provider),
  }

  if (process.env.DEV === 'true') {
    log('\nLogic addresses of deployed contracts:', logicAddresses, '\n')
  }

  let isFeeTokenChain = false
  const versions: { [key: string]: string | null } = {}

  for (const key of Object.keys(logicAddresses)) {
    // try address-based lookup first (for create2 deployments like v3.2.0+)
    let result = _getVersionOfDeployedContractByAddress(logicAddresses[key])

    if (!result.version) {
      // fall back to metadata hash lookup
      try {
        const metadataHash = await _getMetadataHash(
          logicAddresses[key],
          provider
        )
        if (process.env.DEV === 'true') {
          log(`MetadataHash of deployed ${key}:`, metadataHash)
        }
        result = _getVersionOfDeployedContract(metadataHash)
      } catch {
        // metadata hash extraction can fail for contracts without standard metadata
      }
    }

    versions[key] = result.version
    if (key === 'Bridge' && result.isErc20) isFeeTokenChain = true
    log(
      `Version of deployed ${key}: ${versions[key] ? versions[key] : 'unknown'}`
    )
  }

  // TODO: make this more generic to support other other upgrade paths in the future
  // TODO: also check  osp
  const upgradeRecommendation = _checkForPossibleUpgrades(
    versions,
    isFeeTokenChain,
    chainId
  )

  log(upgradeRecommendation.message)

  return {
    versions,
    upgradeRecommendation,
  }
}

function _checkForPossibleUpgrades(
  currentVersions: {
    [key: string]: string | null
  },
  isFeeTokenChain: boolean,
  parentChainId: bigint
): UpgradeRecommendation {
  // version need to be in descending order
  const targetVersionsDescending = [
    {
      version: 'v3.2.0',
      actionName: 'NitroContracts3Point2Point0UpgradeAction',
    },
    {
      version: 'v3.1.0',
      actionName: 'BOLD UpgradeAction',
    },
    {
      version: 'v2.1.3',
      actionName: 'NitroContracts2Point1Point3UpgradeAction',
    },
    {
      version: 'v2.1.2',
      actionName: 'NitroContracts2Point1Point2UpgradeAction',
    },
    {
      version: 'v2.1.0',
      actionName: 'NitroContracts2Point1Point0UpgradeAction',
    },
    {
      version: 'v1.2.1',
      actionName: 'NitroContracts1Point2Point1UpgradeAction',
    },
  ]

  // if 2.1.3 and 3.1.0 are both possible, then notify and early return
  if (
    _canBeUpgradedToTargetVersion(
      'v2.1.3',
      currentVersions,
      isFeeTokenChain,
      parentChainId
    ) &&
    _canBeUpgradedToTargetVersion(
      'v3.1.0',
      currentVersions,
      isFeeTokenChain,
      parentChainId
    )
  ) {
    return {
      message:
        'This deployment can be upgraded to both v2.1.3 and v3.1.0. v3.1.0 is recommended',
      upgradePaths: [
        {
          actionName: 'NitroContracts2Point1Point3UpgradeAction',
          targetVersion: 'v2.1.3',
          isRecommendedVersion: false,
        },
        {
          actionName: 'BOLDUpgradeAction',
          targetVersion: 'v3.1.0',
          isRecommendedVersion: true,
        },
      ],
    }
  }

  let canUpgradeTo = ''
  let canUpgradeToActionName = ''
  for (const target of targetVersionsDescending.reverse()) {
    if (
      _canBeUpgradedToTargetVersion(
        target.version,
        currentVersions,
        isFeeTokenChain,
        parentChainId
      )
    ) {
      if (canUpgradeTo === '') {
        canUpgradeTo = target.version
        canUpgradeToActionName = target.actionName
      } else {
        throw new Error('Multiple upgrade paths found')
      }
    }
  }
  if (canUpgradeTo !== '') {
    return {
      message: `This deployment can be upgraded to ${canUpgradeTo} using ${canUpgradeToActionName}`,
      upgradePaths: [
        {
          actionName: canUpgradeToActionName,
          targetVersion: canUpgradeTo,
          isRecommendedVersion: true,
        },
      ],
    }
  }

  return {
    message: 'No upgrade path found',
  }
}

function _canBeUpgradedToTargetVersion(
  targetVersion: string,
  currentVersions: {
    [key: string]: string | null
  },
  isFeeTokenChain: boolean,
  parentChainId: bigint,
  verbose: boolean = false
): boolean {
  if (verbose)
    console.log('\nChecking if deployment can be upgraded to', targetVersion)

  let supportedSourceVersionsPerContract: { [key: string]: string[] } = {}

  if (targetVersion === 'v3.2.0') {
    supportedSourceVersionsPerContract = {
      Inbox: ['v3.1.0'],
      Outbox: ['v3.1.0'],
      Bridge: ['v3.1.0'],
      RollupEventInbox: ['any'],
      RollupProxy: ['any'],
      RollupAdminLogic: ['v3.1.0'],
      RollupUserLogic: ['v3.1.0'],
      ChallengeManager: ['v3.1.0'],
      SequencerInbox: ['v3.1.0'],
    }
  } else if (targetVersion === 'v3.1.0') {
    // todo: remove once nitro supports bold for L3's
    if (parentChainId !== 1n && parentChainId !== 11155111n) {
      supportedSourceVersionsPerContract = {
        Inbox: [],
        Outbox: [],
        Bridge: [],
        RollupEventInbox: [],
        RollupProxy: [],
        RollupAdminLogic: [],
        RollupUserLogic: [],
        ChallengeManager: [],
        SequencerInbox: [],
      }
    } else {
      // v3.1.0 will upgrade bridge, inbox, rollupEventInbox, outbox, sequencerInbox, rollup logics, challengeManager
      supportedSourceVersionsPerContract = {
        Inbox: [
          'v1.1.0',
          'v1.1.1',
          'v1.2.0',
          'v1.2.1',
          'v1.3.0',
          'v2.0.0',
          'v2.1.0',
          'v2.1.1',
          'v2.1.2',
          'v2.1.3',
        ],
        Outbox: ['any'],
        Bridge: [
          'v1.1.0',
          'v1.1.1',
          'v1.2.0',
          'v1.2.1',
          'v1.3.0',
          'v2.0.0',
          'v2.1.0',
          'v2.1.1',
          'v2.1.2',
          'v2.1.3',
        ],
        RollupEventInbox: ['any'],
        RollupProxy: ['any'],
        RollupAdminLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2', 'v2.1.3'],
        RollupUserLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2', 'v2.1.3'],
        ChallengeManager: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2', 'v2.1.3'],
        SequencerInbox: [
          'v1.2.1',
          'v1.3.0',
          'v2.0.0',
          'v2.1.0',
          'v2.1.1',
          'v2.1.2',
          'v2.1.3',
        ],
      }
      if (isFeeTokenChain) {
        supportedSourceVersionsPerContract.Bridge = [
          'v2.0.0',
          'v2.1.0',
          'v2.1.1',
          'v2.1.2',
          'v2.1.3',
        ]
      }
    }
  } else if (targetVersion === 'v2.1.3') {
    // v2.1.3 will upgrade the SequencerInbox and Inbox contracts to prevent 7702 accounts from calling certain functions
    // v2.1.3 or v3.1.0 must be performed before the parent chain upgrades with 7702
    // has the same prerequisites as v3.1.0
    supportedSourceVersionsPerContract = {
      Inbox: [
        'v1.1.0',
        'v1.1.1',
        'v1.2.0',
        'v1.2.1',
        'v1.3.0',
        'v2.0.0',
        'v2.1.0',
        'v2.1.1',
        'v2.1.2',
      ],
      Outbox: ['any'],
      Bridge: [
        'v1.1.0',
        'v1.1.1',
        'v1.2.0',
        'v1.2.1',
        'v1.3.0',
        'v2.0.0',
        'v2.1.0',
        'v2.1.1',
        'v2.1.2',
      ],
      RollupEventInbox: ['any'],
      RollupProxy: ['any'],
      RollupAdminLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2'],
      RollupUserLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2'],
      ChallengeManager: ['v2.0.0', 'v2.1.0', 'v2.1.1', 'v2.1.2'],
      SequencerInbox: [
        'v1.2.1',
        'v1.3.0',
        'v2.0.0',
        'v2.1.0',
        'v2.1.1',
        'v2.1.2',
      ],
    }
    if (isFeeTokenChain) {
      supportedSourceVersionsPerContract.Bridge = [
        'v2.0.0',
        'v2.1.0',
        'v2.1.1',
        'v2.1.2',
      ]
    }
  } else if (targetVersion === 'v2.1.2') {
    // v2.1.2 will upgrade the ERC20Bridge contract to set decimals in storage
    // v2.1.2 is only required for custom fee token chains
    // only necessary if ERC20Bridge is < v2.0.0
    // must have performed v2.1.0 upgrade first
    if (!isFeeTokenChain) {
      supportedSourceVersionsPerContract = {
        Inbox: [],
        Outbox: [],
        Bridge: [],
        RollupEventInbox: [],
        RollupProxy: [],
        RollupAdminLogic: [],
        RollupUserLogic: [],
        ChallengeManager: [],
        SequencerInbox: [],
      }
    } else {
      supportedSourceVersionsPerContract = {
        Inbox: [
          'v1.1.0',
          'v1.1.1',
          'v1.2.0',
          'v1.2.1',
          'v1.3.0',
          'v2.0.0',
          'v2.1.0',
          'v2.1.1',
        ],
        Outbox: ['any'],
        Bridge: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
        RollupEventInbox: ['any'],
        RollupProxy: ['any'],
        RollupAdminLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1'],
        RollupUserLogic: ['v2.0.0', 'v2.1.0', 'v2.1.1'],
        ChallengeManager: ['v2.0.0', 'v2.1.0', 'v2.1.1'],
        SequencerInbox: ['v1.2.1', 'v1.3.0', 'v2.0.0', 'v2.1.0', 'v2.1.1'],
      }
    }
  } else if (targetVersion === 'v2.1.0') {
    // v2.1.0 will upgrade rollup logics and challenge manager
    supportedSourceVersionsPerContract = {
      Inbox: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      Outbox: ['any'],
      Bridge: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      RollupEventInbox: ['any'],
      RollupProxy: ['any'],
      RollupAdminLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      RollupUserLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1', 'v1.3.0'],
      ChallengeManager: ['v1.2.1', 'v1.3.0'],
      SequencerInbox: ['v1.2.1', 'v1.3.0', 'v2.0.0', 'v2.1.0'],
    }
  } else if (targetVersion === 'v1.2.1') {
    // v1.2.1 will upgrade sequencer inbox and challenge manager
    supportedSourceVersionsPerContract = {
      Inbox: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      Outbox: ['any'],
      Bridge: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      RollupEventInbox: ['any'],
      RollupProxy: ['any'],
      RollupAdminLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      RollupUserLogic: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      ChallengeManager: ['v1.1.0', 'v1.1.1', 'v1.2.0', 'v1.2.1'],
      SequencerInbox: ['v1.1.0', 'v1.1.1'],
    }
  } else {
    if (verbose) console.log('Unsupported target version')
    return false
  }

  // check if all contracts can be upgraded to target version
  for (const [contract, supportedSourceVersions] of Object.entries(
    supportedSourceVersionsPerContract
  )) {
    if (supportedSourceVersions.includes('any')) {
      continue
    }
    if (!supportedSourceVersions.includes(currentVersions[contract]!)) {
      // found contract that can't be upgraded to target version
      if (verbose) console.log('Cannot upgrade', contract, 'to', targetVersion)
      return false
    }
  }
  // all contracts can be upgraded to target version
  return true
}

function _getVersionOfDeployedContractByAddress(logicAddress: string): {
  version: string | null
  isErc20: boolean
} {
  const normalized = logicAddress.toLowerCase()
  for (const [version] of Object.entries(referentContractAddresses).reverse()) {
    const versionAddresses = referentContractAddresses[version]
    const allAddresses = [
      ...Object.values(versionAddresses.eth).flat(),
      ...Object.values(versionAddresses.erc20).flat(),
      ...versionAddresses.RollupProxy,
      ...versionAddresses.RollupAdminLogic,
      ...versionAddresses.RollupUserLogic,
      ...versionAddresses.ChallengeManager,
    ].map(a => a.toLowerCase())

    if (allAddresses.includes(normalized)) {
      const erc20Addresses = [
        ...Object.values(versionAddresses.erc20).flat(),
      ].map(a => a.toLowerCase())
      if (erc20Addresses.includes(normalized)) {
        return { version, isErc20: true }
      }
      return { version, isErc20: false }
    }
  }
  return { version: null, isErc20: false }
}

function _getVersionOfDeployedContract(metadataHash: string): {
  version: string | null
  isErc20: boolean
} {
  // referentMetadataHashes should be in descending order of version
  // we want to return the lowest version that matches the hash
  for (const [version] of Object.entries(referentMetadataHashes).reverse()) {
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

    const erc20Hashes = [...Object.values(versionHashes.erc20).flat()]

    if (allHashes.includes(metadataHash)) {
      if (erc20Hashes.includes(metadataHash)) {
        return { version, isErc20: true }
      }
      return { version, isErc20: false }
    }
  }
  return { version: null, isErc20: false }
}

async function _getMetadataHash(
  contractAddress: string,
  provider: JsonRpcProvider
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
  provider: JsonRpcProvider
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
  provider: JsonRpcProvider,
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

// Docker / CLI entrypoint
if (require.main === module) {
  const args = process.argv.slice(2)
  if (args.includes('--help')) {
    process.stdout.write(`${HELP_TEXT}\n`)
    process.exit(0)
  }

  const inboxAddress = process.env.INBOX_ADDRESS
  const parentRpcUrl = process.env.PARENT_CHAIN_RPC
  const jsonOutput = process.env.JSON_OUTPUT?.toLowerCase() === 'true'

  if (!inboxAddress) {
    const errorMessage = 'INBOX_ADDRESS env variable should be set'
    if (jsonOutput) {
      process.stderr.write(`${JSON.stringify({ error: errorMessage })}\n`)
      process.exit(1)
    }
    throw new Error(errorMessage)
  }

  if (!parentRpcUrl) {
    const errorMessage = 'PARENT_CHAIN_RPC env variable should be set'
    if (jsonOutput) {
      process.stderr.write(`${JSON.stringify({ error: errorMessage })}\n`)
      process.exit(1)
    }
    throw new Error(errorMessage)
  }

  runChainVersioner(inboxAddress, parentRpcUrl, jsonOutput)
    .then(result => {
      if (jsonOutput) {
        process.stdout.write(`${JSON.stringify(result)}\n`)
      }
      process.exit(0)
    })
    .catch((error: Error) => {
      if (jsonOutput) {
        process.stderr.write(`${JSON.stringify({ error: error.message })}\n`)
      } else {
        console.error(error)
      }
      process.exit(1)
    })
}
