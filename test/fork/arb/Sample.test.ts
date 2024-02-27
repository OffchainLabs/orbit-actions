import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Sample', () => {
  it('should have code at L2 Gateway Router', async () => {
    expect(
      (
        await ethers.provider.getCode(
          '0x5288c571Fd7aD117beA99bF60FE0846C4E84F933'
        )
      ).length
    ).to.be.gt(2)
  })
})
