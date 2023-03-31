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
    // Monday, Jan 2 2023 09:00 UTC
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

  describe('getStartEndOfWeeklyGuessPeriod', function () {
    // Monday, Jan 2 2023 09:00 UTC
    const dateEarly = dayjs.utc('2023-01-02T09:00:00Z')
    // Saturday, Jan 7 2023 09:00 UTC
    const dateLate = dayjs.utc('2023-01-07T09:00:00Z')

    it('should get the correct weekly close guess periods early in the week', async function () {
      const testWeeklyCloseEarly =
        await gudGuessInst.getStartEndOfWeeklyGuessPeriod(dateEarly.unix())
      const weeklyCloseEarlyStartCheck = dayjs
        .utc(`2023-01-08T23:59:59Z`)
        .subtract(7, 'days')
        .subtract(3, 'days')
        .unix()
      const weeklyCloseEarlyEndCheck = dayjs
        .utc(`2023-01-08T23:59:59Z`)
        .subtract(3, 'days')
        .unix()
      expect(testWeeklyCloseEarly.start.toString()).to.be.eq(
        weeklyCloseEarlyStartCheck.toString()
      )
      expect(testWeeklyCloseEarly.end.toString()).to.be.eq(
        weeklyCloseEarlyEndCheck.toString()
      )
    })

    it('should get the correct weekly close guess periods later in the week', async function () {
      const testWeeklyCloseLate =
        await gudGuessInst.getStartEndOfWeeklyGuessPeriod(dateLate.unix())
      const weeklyCloseLateStartCheck = dayjs
        .utc(`2023-01-15T23:59:59Z`)
        .subtract(7, 'days')
        .subtract(3, 'days')
        .unix()
      const weeklyCloseLateEndCheck = dayjs
        .utc(`2023-01-15T23:59:59Z`)
        .subtract(3, 'days')
        .unix()
      expect(testWeeklyCloseLate.start.toString()).to.be.eq(
        weeklyCloseLateStartCheck.toString()
      )
      expect(testWeeklyCloseLate.end.toString()).to.be.eq(
        weeklyCloseLateEndCheck.toString()
      )
    })
  })
})
