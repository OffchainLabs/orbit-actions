import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Sample', () => {
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
