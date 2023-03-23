// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import './interfaces/ITwapUtils.sol';

contract TwapUtils is ITwapUtils {
  function getSqrtPriceX96FromPoolAndInterval(
    address uniswapV3Pool,
    uint32 twapInterval
  ) public view override returns (uint160 sqrtPriceX96) {
    IUniswapV3Pool _pool = IUniswapV3Pool(uniswapV3Pool);
    if (twapInterval == 0) {
      // return the current price if twapInterval == 0
      (sqrtPriceX96, , , , , , ) = _pool.slot0();
    } else {
      uint32[] memory secondsAgo = new uint32[](2);
      secondsAgo[0] = twapInterval; // from
      secondsAgo[1] = 0; // to (now)

      (int56[] memory tickCumulatives, ) = _pool.observe(secondsAgo);

      // tick(imprecise as it's an integer) to price
      sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
      );
    }
  }

  // https://docs.uniswap.org/sdk/v3/guides/fetching-prices
  function getSqrtPriceX96FromPriceX96(
    uint256 priceX96
  ) public pure override returns (uint160 sqrtPriceX96) {
    return uint160(_sqrt(priceX96) * 2 ** (96 / 2));
  }

  // will output priceX96 = (token1 / token0) * 2**96, with decimals being included in price
  //
  // frontend would need to evaluate (priceX96 / 2**96) * 10**t0Decimals / 10**t1Decimals to get actual
  // price ratio without needing to consider 2**96 multiplier or each token's decimals
  function getPriceX96FromSqrtPriceX96(
    uint160 sqrtPriceX96
  ) public pure override returns (uint256 priceX96) {
    return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
  }

  // https://ethereum.stackexchange.com/a/2913
  function _sqrt(uint256 x) internal pure returns (uint256 y) {
    uint256 z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }
}
