// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RareBlocksInterface {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external virtual;

  function ownerOf(uint256 tokenId)
    external
    view
    virtual
    returns (address owner);

  function getApproved(uint256 tokenId)
    external
    view
    virtual
    returns (address operator);
}

contract RentingPooled is IERC721Receiver, Ownable {
  RareBlocksInterface rareBlocks;

  uint256 deployDate;
  uint256 totalTimesRented;
  uint256 rentalMultiplier; //

  mapping(address => uint256[]) tokenOwners; // Track staked tokens

  address rareBlocksContractAddress; // Rareblocks NFT contract address
  address treasuryAddress; // Treasury

  uint256 totalOutstandingShares = 0; // Amount of outstanding shares of the treasury
  uint256 totalTokenStaked; // Total amount of tokens staked
  mapping(address => uint256) sharesPerWallet; // Amount of shares a wallet holds;

  uint256 treasury;

  struct Rent {
    address renter;
    uint256 rentDate;
  }
  mapping(address => Rent) renters; // Track renter

  event Rented(address indexed _address); // Renting event
  event Staked(address indexed from, uint256 indexed tokenId, address sender); // Staking a pass
  event Unstaked(address indexed _from, uint256 indexed tokenId); // Unstaking a pass
  event UpdateTreasury(address indexed newAddress); // Change treasure wallet address
  event SetRareblocksContractAddress(address indexed newAddress); // When a token has added to the rent list

  constructor() {
    setRareblocksContractAddress(0x1bb191e56206e11b14117711C333CC18b9861262);
    treasuryAddress = 0x96E7C3bAA9c1EF234A1F85562A6C444213a02E0A;

    deployDate = block.timestamp;
    rentalMultiplier = 2;
  }

  // Set RarBlocks contract address
  function setRareblocksContractAddress(address _rbAddress) public onlyOwner {
    rareBlocksContractAddress = _rbAddress;
    rareBlocks = RareBlocksInterface(_rbAddress);
    emit SetRareblocksContractAddress(_rbAddress);
  }

  // Change treasury address
  function updateTreasury(address _newAddress) external onlyOwner {
    treasuryAddress = _newAddress;
    emit UpdateTreasury(_newAddress);
  }

  // Function called when being transfered a ERC721 token
  // On receival add staking information to struct Stake
  function onERC721Received(
    address _from,
    address,
    uint256 _tokenId,
    bytes calldata
  ) external returns (bytes4) {
    require(msg.sender == rareBlocksContractAddress, "Wrong NFT"); // Make sure only Rareblocks NFT can be staked. msg.sender is always contract address of NFT.

    tokenOwners[_from].push(_tokenId);

    emit Staked(_from, _tokenId, msg.sender);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  // Rent a pass
  function rent() external payable {
    /// @dev Check months since deployed. This assume 1 month is 30 days.
    uint256 monthsSinceDeploy = (block.timestamp - deployDate) /
      1000 /
      60 /
      60 /
      24 /
      30;

    /// @dev Get max rent limit per month multiplied by rental multiplier.
    /// @notice If no one rent out passes within the month, the max limit will keep on increasing.
    uint256 rentalMaxLimit = monthsSinceDeploy *
      totalTokenStaked *
      rentalMultiplier;

    require(rentalMaxLimit > totalTimesRented, "Maximum rental times reached");

    /// @dev A wallet can only rent one pass at a time.
    Rent memory renter = renters[msg.sender];
    require(
      block.timestamp > renter.rentDate + 30 days,
      "You still have an active rental"
    );

    /// @dev Map renter so we can easily check if rent is active or not.
    /// @notice If Renter rents again the next month, we just need to override the struct.
    renters[msg.sender] = Rent({
      renter: msg.sender,
      rentDate: uint256(block.timestamp)
    });

    /// @dev Increment total times rented
    totalTimesRented += 1;

    emit Rented(msg.sender);
  }

  // List all tokens staked by address
  function getTokensStakedByAddress(address _address)
    public
    view
    returns (uint256[] memory)
  {
    return tokenOwners[_address];
  }

  function removeTokenIdFromTokenOwners(uint256 tokenId) internal {
    for (uint256 i = 0; i < tokenOwners[msg.sender].length; i++) {
      if (tokenOwners[msg.sender][i] == tokenId) {
        removeTokenIdFromTokenOwnersByIndex(i);
      }
    }
  }

  function removeTokenIdFromTokenOwnersByIndex(uint256 _index) internal {
    require(_index < tokenOwners[msg.sender].length, "index out of bound");

    for (uint256 i = _index; i < tokenOwners[msg.sender].length - 1; i++) {
      tokenOwners[msg.sender][i] = tokenOwners[msg.sender][i + 1];
    }
    tokenOwners[msg.sender].pop();
  }

  function stakeAndPurchaseTreasuryStock(uint256 _tokenId) public payable {
    uint256 sharePrice = treasury / totalOutstandingShares; // Amount of value in treasury per share = share price;

    require(msg.value == sharePrice, "Not enough value to purchase share");

    require(
      rareBlocks.ownerOf(_tokenId) == msg.sender,
      "You do not own this token."
    );
    require(
      rareBlocks.getApproved(_tokenId) == address(this),
      "You did not approve this contract to transfer."
    );

    rareBlocks.safeTransferFrom(msg.sender, address(this), _tokenId); // Transfer token to contract

    totalOutstandingShares++;
    sharesPerWallet[msg.sender]++;
  }

  // Unstake token and send back to users wallet
  function unstakeAccessPass(uint256 _tokenId) external {
    require(tokenOwners[msg.sender].length > 0, "You haven't staked a token.");

    bool hasTokenStaked = false;
    for (uint256 i = 0; i < tokenOwners[msg.sender].length; i++) {
      if (_tokenId == tokenOwners[msg.sender][i]) {
        hasTokenStaked = true;
      }
    }

    require(hasTokenStaked, "This tokenId has not been staked by you.");

    rareBlocks.safeTransferFrom(address(this), msg.sender, _tokenId); // Send back token to owner
    removeTokenIdFromTokenOwners(_tokenId); // Remove staked tokenId

    uint256 valuePerShare = treasury / totalOutstandingShares; // New price per share
    uint256 totalSharesOwned = sharesPerWallet[msg.sender]; // Total amount of owned shares
    uint256 totalPayoutPrice = valuePerShare * totalSharesOwned; // Price to pay for selling shares

    totalOutstandingShares =
      totalOutstandingShares -
      sharesPerWallet[msg.sender]; // Reduce amount of shares outstanding
    sharesPerWallet[msg.sender] = 0; // Remove shares for wallet

    (bool success, ) = payable(msg.sender).call{ value: totalPayoutPrice }(""); // Pay commission to staker
    emit Unstaked(msg.sender, _tokenId);
    require(success, "Failed to send Ether");
  }
}
