const { expect } = require('chai')
const BigNumber = require('bignumber.js')

let TwapUtilsFactory
let twapUtilsInstance

describe('TwapUtils', function () {
  before(async () => {
    // const [owner] = await ethers.getSigners();

    // factory
    TwapUtilsFactory = await ethers.getContractFactory('TwapUtils')

    // deploy contract, store result in global twapUtilsInstance var for tests that follow
    twapUtilsInstance = await TwapUtilsFactory.deploy()

    // contract successfully deployed and has an address
    expect(twapUtilsInstance.address).to.have.lengthOf(42)
  })

  describe('getPriceX96FromSqrtPriceX96 & getSqrtPriceX96FromPriceX96', function () {
    const priceRaw = new BigNumber('1000')
    const exactPriceX96 = priceRaw.times(new BigNumber(2).pow(96))
    const sqrtPriceX96 = exactPriceX96
      .sqrt()
      .times(new BigNumber(2).pow(new BigNumber(96).div(2)))
    const roundedPriceX96 = new BigNumber(sqrtPriceX96.toFixed(0))
      .pow(2)
      .div(new BigNumber(2).pow(96))

    it('should return the correct priceX96 from provided sqrtPriceX96', async function () {
      const testPriceX96 = await twapUtilsInstance.getPriceX96FromSqrtPriceX96(
        sqrtPriceX96.toFixed(0)
      )
      expect(testPriceX96.toString()).to.be.eq(roundedPriceX96.toFixed(0))
    })

    it('should return the correct sqrtPriceX96 from provided priceX96', async function () {
      const testSqrtPriceX96 =
        await twapUtilsInstance.getSqrtPriceX96FromPriceX96(
          roundedPriceX96.toFixed(0)
        )
      const sqrtDiff = sqrtPriceX96.minus(testSqrtPriceX96.toString()).abs()
      expect(sqrtDiff.div(sqrtPriceX96).toNumber()).to.be.lessThan(0.000001)
    })
  })
})
