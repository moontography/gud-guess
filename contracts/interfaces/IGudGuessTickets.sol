// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IGudGuessTickets is IERC721 {
  struct TicketMetadata {
    uint256 weeklyClose;
    address token;
    address primaryPool;
    address nativeStablePool; // address(0) if not applicable
    uint256 priceUSDX96;
    uint32 winningsWeight;
  }

  function tickets(
    uint256 tokenId
  ) external view returns (TicketMetadata memory);
}
