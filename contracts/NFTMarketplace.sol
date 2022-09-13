// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4; 

// using ERC721 standard for the funnctionality.
// ERC721 os an open standard on non fungable token on ETH.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

// public means available from the client application
// view means it's not doing any transaction work

// Creating our contract ->Inherited from ERC721URIStorage
contract NFTMarketplace is ERC721URIStorage {
  // enabling the counter utility to keep track of the number of tokens
  using Counters for Counters.Counter;

    // when the first token is minted it'll get a value of zero, the second one is one
  // and then using counters this we'll increment token ids

  // type is of counter 
  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  // listing fee of NFT
  uint256 listingPrice = 0 ether;

  // creating owner of the contract
  // owner gets commision from all sales
  address payable owner;

  // to keep up with all items created a int which is item id is passed (uint256)
  // and the item is stored in the mapping so it returns an market item
  // so any market item can be accessed by its id
  mapping(uint256 => MarketItem) private idToMarketItem;

  // creating a struct aka object structure for market item object
  struct MarketItem {
    uint256 tokenId;
    // payable means it can receive ETH
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;
  }

  // have an event for when a market item is created.
  // this event matches the MarketItem
  // format is func declare format in java with params
  // will be used
  event MarketItemCreated (
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  // the owner of the contract is the one deploying it
  // the cunstructor function
  constructor() ERC721("Metaverse Tokens", "METT") {
    owner = payable(msg.sender);
  }

  // Updates the listing price of the contract 
  // function with public means this function can receive eth
  // public so it can be called from the client application
  function updateListingPrice(uint _listingPrice) public payable {
  // only owner can update the listing price. below is basically an if statement
    require(owner == msg.sender, "Only marketplace owner can update listing price.");
    listingPrice = _listingPrice;
  }

  // view means it's not doing any transaction work
  // will return an int 256
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  // mints the token and lists it
  // memory means it store data to run contract
  // returns uint
  function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
    // increasing count of tokenIDs to get fresh 
    _tokenIds.increment();
    // create a variable that get's the current value of the tokenIds (0, 1, 2...)
    uint256 newTokenId = _tokenIds.current();
    // mint the token with (makes it unique)
    // inbuilt function from ERC721 start with _
    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    createMarketItem(newTokenId, price);
    // token is minted and now is sellable
    // now can return the id to the client side so we can work with it
    return newTokenId;
  }

  // private since only createToken function uses it
  function createMarketItem(uint256 tokenId, uint256 price) private {
    // require a certain CONDITION, in this case price greater than 0
    require(price > 0, "Price must be at least 1 ETH");
    // require that the users sending in the transaction is sending in the correct amount
    require(msg.value == listingPrice, "Price must be equal to listing price");

    // create the mapping for the market items 
    // payable(address(0)) is the owner. 
    // currently there's no owner as the seller is putting it to market so it's an empty address
    // last value is boolean for sold, its false because we just put it so it's not sold yet
    // this is creating the first market item
    idToMarketItem[tokenId] =  MarketItem(
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price,
      false
    );

    // now to transfer the ownership of the nft to the contract -> next buyer
    // method available on ERC721
    // _transfer(from, to, tokenID)
    _transfer(msg.sender, address(this), tokenId);
    emit MarketItemCreated(
      tokenId,
      msg.sender,
      address(this),
      price,
      false
    );
  }

  // allows someone to resell a token they have purchased 
  function resellToken(uint256 tokenId, uint256 price) public payable {
    require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
    require(msg.value == listingPrice, "Price must be equal to listing price");
    // changing properties of object based on seller needs
    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].price = price;
    idToMarketItem[tokenId].seller = payable(msg.sender);
    // address(this) means nft belongs to the contract/website not a user anymore
    idToMarketItem[tokenId].owner = payable(address(this));
    // as item is not sold anymore as it's relisted
    _itemsSold.decrement();
    // from owner to contract/website
    _transfer(msg.sender, address(this), tokenId);
  }
  
  // Creates the sale of a marketplace item 
  // Transfers ownership of the item, as well as funds between parties 
  function createMarketSale(uint256 tokenId) public payable {
    uint price = idToMarketItem[tokenId].price;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].sold = true;
    // seller changes from nft market place to no seller
    idToMarketItem[tokenId].seller = payable(address(0));
    _itemsSold.increment();
    
    // transfer the NFT ownership from the seller to the buyer
    _transfer(address(this), msg.sender, tokenId);
    payable(owner).transfer(listingPrice); // change listing price to something else when deply so website can get fee on each sale
    payable(idToMarketItem[tokenId].seller).transfer(msg.value);
  }

  // Returns all unsold market items 
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _tokenIds.current();
    uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    // looping over the number of items created and incremnet htat number if we have an empty address 
    // address 0 means it's not sold and is listed
    // empty array called items
    // the type of the element in the array is marketitem, and the unsolditemcount is the lenght
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      // check to see if the item is unsold -> checking if the owner is an empty address -> then it's unsold
      // above, wwhen creating a new market item, the address to be an empty address
      // the address get's populated if the item is sold
      if (idToMarketItem[i + 1].owner == address(this)) {
        // the id of the item that we're currently interracting with
        uint currentId = i + 1;
        // get the mapping of the idtomarketitem with the -> gives us the reference to the marketitem
        MarketItem storage currentItem = idToMarketItem[currentId];
        // insert the market item to the items array
        items[currentIndex] = currentItem;
        // increment the current index
        currentIndex += 1;
      }
    }
    return items;
  }

   // Returns only items that a user has purchased 
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _tokenIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    // gives us the number of items that we own
    for (uint i = 0; i < totalItemCount; i++) {
      // check if nft is mine
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);

    for (uint i = 0; i < totalItemCount; i++) {
      // check if nft is mine
      if (idToMarketItem[i + 1].owner == msg.sender) {
        // get the id of the market item
        uint currentId = i + 1;
        // get the reference to the current market item
        MarketItem storage currentItem = idToMarketItem[currentId];
        // insert into the array
        items[currentIndex] = currentItem;
        // increment the index
        currentIndex += 1;
      }
    }
    return items;
  }

  // Returns only items a user has listed 
  // same as fetchMyNFTs but we're checking if the seller is the current user
  function fetchItemsListed() public view returns (MarketItem[] memory) {
    uint totalItemCount = _tokenIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    
    return items;
  }
}