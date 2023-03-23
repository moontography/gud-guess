// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './interfaces/BokkyPooBahsDateTimeLibrary.sol';
import './TwapUtils.sol';

contract PriceLogic is TwapUtils {
  function getWeeklyCloseFromTimestamp(
    uint256 _timestamp
  ) public pure returns (uint256) {
    uint256 _diffFromMidnight = _timestamp % 1 days;
    uint256 _thisComingMidnight = _timestamp + 1 days - _diffFromMidnight;
    uint256 _todayDOW = BokkyPooBahsDateTimeLibrary.getDayOfWeek(_timestamp);
    uint256 _daysUntilEOW = 7 - _todayDOW;
    return _thisComingMidnight + (_daysUntilEOW * 1 days);
  }

  // returns price USD/priceToken, normalized by 2^96
  function getCurrentPoolPriceUSDX96(
    address _priceToken,
    IUniswapV3Pool _pricePool,
    IUniswapV3Pool _nativeStablePool,
    uint32 _twapInterval,
    address _WETH9,
    bool _isPoolPairedWETH9
  ) public view returns (uint256) {
    if (_isPoolPairedWETH9) {
      uint256 _priceMainX96 = _getNormalizedPriceX96(
        _pricePool,
        _WETH9,
        _twapInterval
      );

      address _token0 = _nativeStablePool.token0();
      address _token1 = _nativeStablePool.token1();
      uint256 _priceStableWETH9X96 = _getNormalizedPriceX96(
        _nativeStablePool,
        _token0 == _WETH9 ? _token1 : _token0,
        _twapInterval
      );

      return (_priceStableWETH9X96 * _priceMainX96) / FixedPoint96.Q96;
    }

    // assume main pool is paired with a stable to directly calc USD price
    address _mainToken0 = _pricePool.token0();
    address _mainToken1 = _pricePool.token1();
    return
      _getNormalizedPriceX96(
        _pricePool,
        _mainToken0 == _priceToken ? _mainToken1 : _mainToken0,
        _twapInterval
      );
  }

  // takes a pool and calculates the price based on a numerator token (usually token1)
  // and removes decimals from respective tokens while normalizing by 2^96
  function _getNormalizedPriceX96(
    IUniswapV3Pool _pool,
    address _numeratorToken,
    uint32 _twapInterval
  ) internal view returns (uint256) {
    address _token1 = _pool.token1();
    uint8 _decimals0 = ERC20(_pool.token0()).decimals();
    uint8 _decimals1 = ERC20(_token1).decimals();
    uint256 _priceX96 = getSqrtPriceX96FromPoolAndInterval(
      address(_pool),
      _twapInterval
    );
    uint256 _correctedPriceX96 = _token1 == _numeratorToken
      ? _priceX96
      : FixedPoint96.Q96 ** 2 / _priceX96;
    return
      _token1 == _numeratorToken
        ? (_correctedPriceX96 * 10 ** _decimals0) / 10 ** _decimals1
        : (_correctedPriceX96 * 10 ** _decimals1) / 10 ** _decimals0;
  }
}
