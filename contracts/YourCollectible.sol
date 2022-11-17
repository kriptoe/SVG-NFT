pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './Base64.sol';
import "hardhat/console.sol";

import './HexStrings.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string[] public countryNames = ["Argentina", "Australia", "Belgium", "Brazil", "Cameroon", "Canada","Costa Rica","Croatia",
  "Denmark","Ecuador","England","France","Germany","Ghana","Iran","Japan","Korea Republic","Mexico","Morocco","Netherlands","Poland","Portugal","Qatar",
   "Saudi Arabia","Senegal","Serbia","Spain","Switzerland","Tunisia","Uruguay","USA","Wales"];
  uint256 priva  te winner = 99;   // 99 indicates sweepstakes is unavailable for claiming
  uint256[32] countryTotals ;  // how many nfts perc country

  mapping (uint256 => uint256) public countrySelected;  // maps country selected to tokenID
  mapping (uint256 => bool) public hasClaimed;  // to track if prize has been claimed

  constructor() public ERC721("Loogies", "LOOG") {
    // set winner to 99
  }

  function mintPayable( uint256 country) public payable returns (uint256)
  {
    require (balanceOf(msg.sender)==0, "You can only mint one NFT per address");
     require (msg.value >= 0.1 ether , "Minimum cost of NFT is 1 matic");   
    (bool sent, bytes memory data) = address(this).call{value: msg.value}("");
    require(sent, "Failed to send Ether");     
      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);
      countrySelected[id] = country;           // map the country selected to the NFT ID
      countryTotals[country] = countryTotals[country] + 1;
      hasClaimed[id]=false;
      return id;
  }


  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('BET ID #',id.toString()));
      string memory description = string(abi.encodePacked('You selected ',countryNames[countrySelected[id]],' to win the world cup'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "country", "value": "',
                              countryNames[countrySelected[id]],
                              '"}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    string memory svg = string(abi.encodePacked(
      '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));
    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory render = string(abi.encodePacked(
'<svg width="550" height="550">',
'<rect width="400" height="240" stroke="green" stroke-width="2" fill="#fff"></rect>',
'<text x="200" y="100" alignment-baseline="middle" font-size="30" stroke-width="0" stroke="#000" text-anchor="middle">',
countryNames[countrySelected[id]],
'</text><text x="200" y="145" style="font-size:25px;">bet ',
'</text><text x="100" y="40" style="font-size:30px;">'
'⚽ Predictoor ⚽',
'</text><text x="100" y="65" style="font-size:16px;" stroke="blue">2022 FIFA World Cup Sweepstakes</text>',
'<text x="190" y="180" style="font-size:20px;">ID #',
uint2str(id),
'</text></svg>'
      ));

    return render;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }


  function claim() public payable 
  {
      uint256 nftID = tokenOfOwnerByIndex(msg.sender,0);
       
       require(winner !=99 , "Claiming hasn't been activated");   
       require(countrySelected[nftID] == winner, "Your nft isnt the winning country.");
       require(hasClaimed[nftID] == false,"You are inelgible to claim");
       require(balanceOf(msg.sender)>0, "You don't own an NFT");
       hasClaimed[nftID] = true;         // stops from claiming more than once

       //calculate percentage of pool        (bool success, ) = recentWinner.call{value: address(this).balance}("");
       uint256 amount = address(this).balance;
       amount = amount  / countryTotals[winner];  // percentage of winners
       countryTotals[winner] = countryTotals[winner] - 1;
       console.log("amount " , amount);
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send balance");
        
     
  }  


 function setWinner(uint256 countryValue) public onlyOwner{
         winner = countryValue;
 }

 function getCountry(uint256 countryNumber) public view returns (string memory){
           return countryNames[countryNumber];
 } 

// returns how many nfts per country
 function getCountryTotal(uint256 countryNumber) public view returns (uint256){
           return countryTotals[countryNumber];
 } 

 function getWinner() public view returns (uint256){
           return winner;
 } 
  // so contract can receive ether
  receive() external payable{}

}
