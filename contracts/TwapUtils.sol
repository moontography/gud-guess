// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import './interfaces/IERC20Metadata.sol';
import './interfaces/ITwapUtils.sol';

contract TwapUtils is ITwapUtils, Ownable {
  uint32 public override twapInterval = 5 minutes;

  // returns price USD/priceToken removing all decimals
  function getPoolPriceUSDX96(
    address _priceToken,
    address _pricePool,
    address _nativeStablePool,
    address _WETH9,
    bool _isPoolPairedWETH9
  ) public view override returns (uint256) {
    if (_isPoolPairedWETH9) {
      uint256 _priceMainX96 = _getNormalizedPriceX96(
        IUniswapV3Pool(_pricePool),
        _WETH9
      );

      address _token0 = IUniswapV3Pool(_nativeStablePool).token0();
      address _token1 = IUniswapV3Pool(_nativeStablePool).token1();
      uint256 _priceStableWETH9X96 = _getNormalizedPriceX96(
        IUniswapV3Pool(_nativeStablePool),
        _token0 == _WETH9 ? _token1 : _token0
      );

      return (_priceStableWETH9X96 * _priceMainX96) / FixedPoint96.Q96;
    }

    // assume main pool is paired with a stable to directly calc USD price
    address _mainToken0 = IUniswapV3Pool(_pricePool).token0();
    address _mainToken1 = IUniswapV3Pool(_pricePool).token1();
    return
      _getNormalizedPriceX96(
        IUniswapV3Pool(_pricePool),
        _mainToken0 == _priceToken ? _mainToken1 : _mainToken0
      );
  }

  function getSqrtPriceX96FromPoolAndInterval(
    address _poolAddress
  ) public view override returns (uint160 sqrtPriceX96) {
    IUniswapV3Pool _pool = IUniswapV3Pool(_poolAddress);
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

  // takes a pool and calculates the price based on a numerator token (usually token1)
  // and removes decimals from respective tokens while normalizing by 2^96
  function _getNormalizedPriceX96(
    IUniswapV3Pool _pool,
    address _numeratorToken
  ) internal view returns (uint256) {
    address _token1 = _pool.token1();
    uint8 _decimals0 = IERC20Metadata(_pool.token0()).decimals();
    uint8 _decimals1 = IERC20Metadata(_token1).decimals();
    uint160 _sqrtPriceX96 = getSqrtPriceX96FromPoolAndInterval(address(_pool));
    uint256 _priceX96 = getPriceX96FromSqrtPriceX96(_sqrtPriceX96);
    uint256 _correctedPriceX96 = _token1 == _numeratorToken
      ? _priceX96
      : FixedPoint96.Q96 ** 2 / _priceX96;
    return
      _token1 == _numeratorToken
        ? (_correctedPriceX96 * 10 ** _decimals0) / 10 ** _decimals1
        : (_correctedPriceX96 * 10 ** _decimals1) / 10 ** _decimals0;
  }

  function setTwapInterval(uint32 _seconds) external onlyOwner {
    require(_seconds <= 1 hours, 'SETTWAPINT');
    twapInterval = _seconds;
  }
}
