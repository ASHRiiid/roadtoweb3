// SPDX-License-Identifier: GPL-3.0



pragma solidity ^0.8.4;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/Strings.sol";



// Chainlink Imports

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// This import includes functions from both ./KeeperBase.sol and

// ./interfaces/KeeperCompatibleInterface.sol

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";



import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";



// Dev imports. This only works on a local dev network

// and will not work on any test or main livenets.

import "hardhat/console.sol";



contract ABC is ERC721URIStorage, Ownable, VRFConsumerBaseV2, KeeperCompatibleInterface {

using Counters for Counters.Counter;



Counters.Counter private _tokenIdCounter;

uint public interval;

uint public lastTimeStamp;



AggregatorV3Interface public priceFeed;

int256 public currentPrice;



// IPFS URIs for the dynamic nft graphics/metadata.

// NOTE: These connect to my IPFS Companion node.

// You should upload the contents of the /ipfs folder to your own node for development.

string[] bullUrisIpfs = [

"https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",

"https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",

"https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"

];

string[] bearUrisIpfs = [

"https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",

"https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",

"https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"

];





// random

VRFCoordinatorV2Interface COORDINATOR;



// Your subscription ID.

uint64 s_subscriptionId;



// Goerli coordinator. For other networks,

// see https://docs.chain.link/docs/vrf-contracts/#configurations

address vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;



// The gas lane to use, which specifies the maximum gas price to bump to.

// For a list of available gas lanes on each network,

// see https://docs.chain.link/docs/vrf-contracts/#configurations

bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;



// Depends on the number of requested values that you want sent to the

// fulfillRandomWords() function. Storing each word costs about 20,000 gas,

// so 100,000 is a safe default for this example contract. Test and adjust

// this limit based on the network that you select, the size of the request,

// and the processing of the callback request in the fulfillRandomWords()

// function.

uint32 callbackGasLimit = 100000;



// The default is 3, but you can set this higher.

uint16 requestConfirmations = 3;



// For this example, retrieve 2 random values in one request.

// Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.

uint32 numWords = 2;

uint256[] public s_randomWords;

uint256 public s_requestId;



event TokensUpdated(string marketTrend);



constructor(uint updateInterval, address _priceFeed, uint64 subscriptionId) ERC721("Bull&Bear", "BBTK") VRFConsumerBaseV2(vrfCoordinator) {

interval = updateInterval;

lastTimeStamp = block.timestamp;



priceFeed = AggregatorV3Interface(_priceFeed);

currentPrice = getLatestPrice();



COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

s_subscriptionId = subscriptionId;

}



function safeMint(address to) public {

// Current counter value will be the minted token's token ID.

uint256 tokenId = _tokenIdCounter.current();



// Increment it so next time it's correct when we call .current()

_tokenIdCounter.increment();



// Mint the token

_safeMint(to, tokenId);



// Default to a bull NFT

string memory defaultUri = bullUrisIpfs[s_randomWords[0]%3];

_setTokenURI(tokenId, defaultUri);



console.log(

"DONE!!! minted token ",

tokenId,

" and assigned token url: ",

defaultUri

);

}



function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory /*performData*/){

upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

}



function performUpkeep(bytes calldata) external override{

if((block.timestamp - lastTimeStamp) > interval){

lastTimeStamp = block.timestamp;

int latestPrice = getLatestPrice();



if(latestPrice == currentPrice){

return;

}else if(latestPrice < currentPrice){

updateAllTokenUris("bears");

}else{

updateAllTokenUris("bull");

}



currentPrice = latestPrice;

}

}



function getLatestPrice() public view returns(int256){

(,

int price,

,

,) = priceFeed.latestRoundData();

return price;

}



function updateAllTokenUris(string memory trend) internal{

if(compareStrings("bears", trend)){

for(uint i=0; i< _tokenIdCounter.current(); i++){

_setTokenURI(i,bearUrisIpfs[s_randomWords[0]%3]);

}

}else {

for(uint i=0; i< _tokenIdCounter.current(); i++){

_setTokenURI(i,bullUrisIpfs[s_randomWords[0]%3]);

}

}



emit TokensUpdated(trend);

}



function setInterval(uint256 newInterval) public onlyOwner{

interval = newInterval;

}



function setPriceFeed(address newFeed) public onlyOwner{

priceFeed = AggregatorV3Interface(newFeed);

}



function compareStrings(string memory a, string memory b) internal pure returns (bool){

return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));

}



// The following functions are overrides required by Solidity.

function _beforeTokenTransfer(

address from,

address to,

uint256 tokenId

) internal override(ERC721) {

super._beforeTokenTransfer(from, to, tokenId);

}



function _burn(uint256 tokenId)

internal

override(ERC721URIStorage)

{

super._burn(tokenId);

}



function tokenURI(uint256 tokenId)

public

view

override(ERC721URIStorage)

returns (string memory)

{

return super.tokenURI(tokenId);

}



function supportsInterface(bytes4 interfaceId)

public

view

override(ERC721)

returns (bool)

{

return super.supportsInterface(interfaceId);

}



// Assumes the subscription is funded sufficiently.

function requestRandomWords() external onlyOwner {

// Will revert if subscription is not set and funded.

s_requestId = COORDINATOR.requestRandomWords(

keyHash,

s_subscriptionId,

requestConfirmations,

callbackGasLimit,

numWords

);

}



function fulfillRandomWords(

uint256, /* requestId */

uint256[] memory randomWords

) internal override {

s_randomWords = randomWords;

}

}
