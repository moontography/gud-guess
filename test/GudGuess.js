const { expect } = require('chai')
const dayjs = require('dayjs')
var utc = require('dayjs/plugin/utc')

dayjs.extend(utc)

let GudGuessFactory
let gudGuessInst

const zeroAddy = '0x0000000000000000000000000000000000000000'

describe('GudGuess', function () {
  before(async () => {
    // const [owner] = await ethers.getSigners();

    // factory
    GudGuessFactory = await ethers.getContractFactory('GudGuess')

    // deploy contract, store result in global gudGuessInst var for tests that follow
    gudGuessInst = await GudGuessFactory.deploy(
      zeroAddy,
      zeroAddy,
      zeroAddy,
      zeroAddy,
      zeroAddy,
      true,
      zeroAddy,
      zeroAddy
    )

    // contract successfully deployed and has an address
    expect(gudGuessInst.address).to.have.lengthOf(42)
  })

  describe('getWeeklyCloseFromTimestamp', function () {
    // Monday, Jan 2 2023
    const date = dayjs.utc('2023-01-02T09:00:00Z')

    it('should return the correct weekly close', async function () {
      const testWeeklyClose = await gudGuessInst.getWeeklyCloseFromTimestamp(
        date.unix()
      )
      const weeklyCloseCheck = dayjs
        .utc(date)
        .add(7, 'days')
        .subtract(9, 'hours')
        .subtract(1, 'second')
        .unix()
      expect(testWeeklyClose.toString()).to.be.eq(weeklyCloseCheck.toString())
    })
  })
})
