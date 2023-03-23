# The Gud Price (TGP)

https://thegudprice.com

## Compile

```sh
$ npx hardhat compile
```

## Deploy

If your contract requires extra constructor arguments, you'll have to specify them in [deploy options](https://hardhat.org/plugins/hardhat-deploy.html#deployments-deploy-name-options).

```sh
$ CONTRACT_NAME=TheGudPrice npx hardhat run --network goerli scripts/deploy.js
$ # lpCreatePool(3000, priceX96)
$ # lpCreatePool(10000, priceX96)
$ # lpCreatePosition(3000, 50)
$ # lpCreatePosition(10000, 100)
$ # launch()
```

## Verify

```sh
$ npx hardhat verify CONTRACT_ADDRESS --network goerli
```

## Flatten

You generally should not need to do this simply to verify in today's compiler version (0.8.x), but should you ever want to:

```sh
$ npx hardhat flatten {contract file location} > output.sol
```
