import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Counter__factory } from '../../typechain-types'

describe('Counter', () => {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployCounterFixture() {
    const signer = (await ethers.getSigners())[0]
    const counter = await new Counter__factory(signer).deploy()
    await counter.deploymentTransaction()!.wait()
    return { counter, signer }
  }

  describe('Deployment', () => {
    it('should deploy the contract', async () => {
      const { counter } = await loadFixture(deployCounterFixture)
      expect(await counter.getAddress()).to.be.properAddress
    })
  })
})
