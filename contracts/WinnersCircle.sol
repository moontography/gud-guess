// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import './interfaces/IGudGuessTickets.sol';
import './interfaces/IWinnersCircle.sol';

contract WinnersCircle is IWinnersCircle {
  address public immutable owner;
  IGudGuessTickets public gpTickets;

  struct WinningMetadata {
    uint256 totalWinningsETH;
    uint256 winningPriceX96;
    uint256 totalWinningsWeight;
  }

  // weekly close timestamp => metadata
  mapping(uint256 => WinningMetadata) public weeklyCloseInfo;
  // tokenId => was prize claimed
  mapping(uint256 => bool) public ticketsClaimed;

  modifier onlyOwner() {
    require(owner == msg.sender, 'OWNER');
    _;
  }

  event ClaimWinnings(
    uint256 indexed tokenId,
    address indexed wallet,
    uint256 indexed weeklyClose,
    uint256 amountClaimed
  );
  event CloseWeekly(
    uint256 indexed weeklyClose,
    uint256 closePriceX96,
    uint256 totalWinningsWeight
  );

  constructor(address _owner, IGudGuessTickets _gpTickets) {
    owner = _owner;
    gpTickets = _gpTickets;
  }

  function closeWeeklyAndAddWinnings(
    uint256 _weeklyClose,
    uint256 _priceX96,
    uint256 _totalWinningsWeight
  ) external payable override onlyOwner {
    weeklyCloseInfo[_weeklyClose] = WinningMetadata({
      totalWinningsETH: msg.value,
      winningPriceX96: _priceX96,
      totalWinningsWeight: _totalWinningsWeight
    });
    emit CloseWeekly(_weeklyClose, _priceX96, _totalWinningsWeight);
  }

  function claimTicketWinnings(uint256 _tokenId) external {
    require(!ticketsClaimed[_tokenId], 'CLAIM: claimed');
    ticketsClaimed[_tokenId] = true;

    IGudGuessTickets.TicketMetadata memory _ticket = gpTickets.tickets(
      _tokenId
    );
    WinningMetadata memory _closeMd = weeklyCloseInfo[_ticket.weeklyClose];
    require(_ticket.priceUSDX96 == _closeMd.winningPriceX96, 'CLAIM: price');

    uint256 _amountWon = (_closeMd.totalWinningsETH * _ticket.winningsWeight) /
      _closeMd.totalWinningsWeight;
    uint256 _balBefore = address(this).balance;
    address _owner = gpTickets.ownerOf(_tokenId);
    (bool _success, ) = payable(_owner).call{ value: _amountWon }('');
    require(_success, 'CLAIM: not sent');
    require(address(this).balance >= _balBefore - _amountWon, 'CLAIM: uh oh');
    emit ClaimWinnings(_tokenId, _owner, _ticket.weeklyClose, _amountWon);
  }
}
