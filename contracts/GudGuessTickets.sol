// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IGudGuessTickets.sol';
import './ERC721Enumerable.sol';

contract GudGuessTickets is IGudGuessTickets, ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  address public gudPrice;

  Counters.Counter internal _ids;
  string private baseTokenURI;
  address public royaltyAddress;

  // Royalties basis points (percentage using 2 decimals - 1000 = 100, 500 = 50, 0 = 0)
  uint256 private royaltyBasisPoints = 50; // 5%

  // tokenId => metadata
  mapping(uint256 => TicketMetadata) _tickets;

  event Burn(uint256 indexed tokenId, address indexed owner);
  event Mint(uint256 indexed tokenId, address indexed owner);
  event SetPaymentAddress(address indexed user);
  event SetRoyaltyAddress(address indexed user);
  event SetRoyaltyBasisPoints(uint256 indexed _royaltyBasisPoints);
  event SetBaseTokenURI(string indexed newUri);

  modifier onlyGudPrice() {
    require(msg.sender == gudPrice, 'ONLYTOKEN');
    _;
  }

  constructor(string memory _baseTokenURI) ERC721('Gud Guess Tickets', 'tGG') {
    baseTokenURI = _baseTokenURI;
    gudPrice = msg.sender;
  }

  function tickets(
    uint256 _tokenId
  ) external view override returns (TicketMetadata memory) {
    return _tickets[_tokenId];
  }

  function mint(
    address owner,
    uint256 weeklyClose,
    address token,
    address primaryPool,
    address nativeStablePool,
    uint256 priceUSDX96,
    uint32 winningsWeight
  ) external onlyGudPrice returns (uint256) {
    _ids.increment();
    _safeMint(owner, _ids.current());
    _tickets[_ids.current()] = TicketMetadata({
      weeklyClose: weeklyClose,
      token: token,
      primaryPool: primaryPool,
      nativeStablePool: nativeStablePool,
      priceUSDX96: priceUSDX96,
      winningsWeight: winningsWeight
    });

    emit Mint(_ids.current(), owner);
    return _ids.current();
  }

  // Support royalty info - See {EIP-2981}: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(
    uint256,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 1000);
  }

  function tokenURI(
    uint256 _tokenId
  ) public view virtual override returns (string memory) {
    require(_exists(_tokenId));
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), '.json'));
  }

  // Contract metadata URI - Support for OpenSea: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract.json'));
  }

  // Override supportsInterface - See {IERC165-supportsInterface}
  function supportsInterface(
    bytes4 _interfaceId
  ) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
    return super.supportsInterface(_interfaceId);
  }

  function getLastMintedTokenId() external view returns (uint256) {
    return _ids.current();
  }

  function doesTokenExist(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  function setRoyaltyAddress(address _address) external onlyOwner {
    royaltyAddress = _address;
    emit SetRoyaltyAddress(_address);
  }

  function setRoyaltyBasisPoints(uint256 _points) external onlyOwner {
    royaltyBasisPoints = _points;
    emit SetRoyaltyBasisPoints(_points);
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
    emit SetBaseTokenURI(_uri);
  }

  function _baseURI() internal view returns (string memory) {
    return baseTokenURI;
  }
}
