// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ITwapUtils {
  function getSqrtPriceX96FromPoolAndInterval(
    address uniswapV3Pool,
    uint32 twapInterval
  ) external view returns (uint160 sqrtPriceX96);

  function getSqrtPriceX96FromPriceX96(
    uint256 priceX96
  ) external pure returns (uint160 sqrtPriceX96);

  function getPriceX96FromSqrtPriceX96(
    uint160 sqrtPriceX96
  ) external pure returns (uint256 priceX96);
}
