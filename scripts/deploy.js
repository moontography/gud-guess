async function main() {
  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account:', deployer.address)

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Contract = await ethers.getContractFactory(process.env.CONTRACT_NAME)
  // contract constructor arguments can be passed as parameters in #deploy
  // await Contract.deploy(arg1, arg2, ...)
  // TODO: make configurable through CLI params
  const contract = await Contract.deploy(
    // eth goerli
    // TheGudPrice
    '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
    '0xE592427A0AEce92De3Edee1F18E0157C05861564',
    '',
    '',
    '',
    '',
    '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6'

    // arbitrum mainnet
    // TheGudPrice
    // '0xC36442b4a4522E871399CD717aBDD847Ab11FE88',
    // '0xE592427A0AEce92De3Edee1F18E0157C05861564',
    // '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f',
    // '0x2f5e87C9312fa29aed5c179E456625D79015299c',
    // '0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443',
    // 'true',
    // '0x1F98431c8aD98523631AE4a59f267346ea31F984',
    // '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'
  )

  console.log('Contract address:', contract.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
