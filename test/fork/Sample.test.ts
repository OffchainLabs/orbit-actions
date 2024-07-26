import { expect } from 'chai'
import { ethers } from 'hardhat'
import { reset } from '@nomicfoundation/hardhat-network-helpers'

describe('Sample', () => {
  before(async () => {
    await reset(process.env.ETH_FORK_URL)
  })

  it('should have code at sequencer inbox', async () => {
    expect(
      (
        await ethers.provider.getCode(
          '0x1c479675ad559DC151F6Ec7ed3FbF8ceE79582B6'
        )
      ).length
    ).to.be.gt(2)
  })
})
