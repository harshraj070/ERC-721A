// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Builder is ERC721A, Ownable {
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant maxMint = 5;
    uint256 public maxMintSupply = 100;
    constructor(address initialOwner){
        ERC721a("Web3Builder", "MTK")
        Ownable(initialOwner)
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB/";
    }

    function safeMint(uint256 quantity) public payable{
        require(msg.value >= mintPrice * quantity,"Value is not enough");
        require(_numberMinted(msg.sender)+quantity <= maxMint,"Mint limit");
        require(_totalMinted()+quantity <= maxMintSupply,"SOLD OUT");
        _safeMint(msg.sender, quantity);
    }
}
