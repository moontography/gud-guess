// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './GudGuess.sol';

contract GGLockedOwner is Ownable {
  GudGuess public gg;

  constructor(GudGuess _gg) {
    gg = _gg;
  }

  function collectLiquidityPositionFees(IUniswapV3Pool _pool) external {
    IERC20 _token0 = IERC20(_pool.token0());
    IERC20 _token1 = IERC20(_pool.token1());
    gg.collectLiquidityPositionFees(address(_pool));
    uint256 _bal0 = _token0.balanceOf(address(this));
    if (_bal0 > 0) {
      TransferHelper.safeTransfer(address(_token0), owner(), _bal0);
    }
    uint256 _bal1 = _token1.balanceOf(address(this));
    if (_bal1 > 0) {
      TransferHelper.safeTransfer(address(_token1), owner(), _bal1);
    }
  }

  function setTaxEnabled(bool _enabled) external onlyOwner {
    gg.setTaxEnabled(_enabled);
  }

  function toggleAmm(address _amm) external onlyOwner {
    gg.toggleAmm(_amm);
  }
}
