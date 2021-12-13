// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
Limitations
all pass can only be rented out for 1 month 
the longer you stake, the more expensive it will be to unstake since the loop will be longer
*/

/*
Features
proportional payout per rental depending on how many has been staking at the time
ability to cash out anytime and get proportional payout
ability to increase rent price
*/

/*
Known issue
What if X passes are still under rental. 
current check only check for the expiry of the latest pass being rent out
*/

/*
Todo:
Check what's the gas for all of this lol
*/

contract RentContract {
  uint256 totalStake = 0;
  uint256 rentCount = 0;
  uint256 price = 0.1 ether;
  uint80 latestExpiry;

  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 time;
    uint256 rentCount;
  }

  struct Rent {
    address renter;
    uint256 price;
    uint80 time;
    uint256 rentCount;
    uint256 totalStake;
  }

  mapping(uint16 => Stake) stakes;
  mapping(uint256 => Rent) rents;
  mapping(address => uint256) renterToRent;

  constructor() {}

  function stake(uint16 tokenId) public {
    stakes[tokenId] = Stake({
      tokenId: tokenId,
      owner: msg.sender,
      time: uint80(block.timestamp),
      rentCount: rentCount
    });
    totalStake += 1;
  }

  function rent() public {
    rentCount += 1;
    rents[rentCount] = Rent({
      renter: msg.sender,
      price: price,
      time: uint80(block.timestamp),
      rentCount: rentCount,
      totalStake: totalStake
    });
    renterToRent[msg.sender] = rentCount;
    latestExpiry = uint80(block.timestamp + 30 days);
  }

  function isRent() public view returns (bool) {
    uint256 renter = renterToRent[msg.sender];
    Rent memory renterRent = rents[renter];
    return renterRent.time < renterRent.time + 30 days;
  }

  function unstake(uint16 tokenId) public {
    Stake memory ownerStake = stakes[tokenId];
    if (ownerStake.time < latestExpiry) {
      uint256 payout;
      for (uint256 i = ownerStake.rentCount; i < rentCount; i++) {
        // Maybe add another check here to see if pass has expire or not
        Rent memory renterRent = rents[i];
        payout += renterRent.price / totalStake;
      }
      totalStake -= 1;
      delete stakes[tokenId];
    }
  }

  function claim(uint16 tokenId) public {
    Stake memory ownerStake = stakes[tokenId];
    if (ownerStake.time < latestExpiry) {
      uint256 payout;
      for (uint256 i = ownerStake.rentCount; i < rentCount; i++) {
        Rent memory renterRent = rents[i];
        payout += renterRent.price / totalStake;
      }

      stakes[tokenId] = Stake({
        tokenId: ownerStake.tokenId,
        owner: ownerStake.owner,
        time: uint80(block.timestamp),
        rentCount: rentCount
      });
    }
  }
}
