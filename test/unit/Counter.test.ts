import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Counter', () => {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployCounterFixture() {
    const Counter = await ethers.getContractFactory('Counter')
    const counter = await Counter.deploy()
    return { counter }
  }

  describe('Deployment', () => {
    it('should deploy the contract', async () => {
      const { counter } = await loadFixture(deployCounterFixture)
      expect(await counter.getAddress()).to.be.properAddress
    })
  })
})
