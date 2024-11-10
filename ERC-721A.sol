// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Builder is ERC721A, Ownable {
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant maxMint = 5;
    uint256 public maxMintSupply = 100;
    uint256 public constant refundPeriod = 3 minutes;

    address public refundAddress;

    mapping(uint256 => uint256) public refundEndTimeStamp;
    mapping(uint256 => bool) public hasRefunded;

    constructor(address initialOwner) ERC721A("Web3Builder", "MTK") Ownable(initialOwner) {
        refundAddress = address(this);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB/";
    }

    function safeMint(uint256 quantity) public payable {
        require(msg.value >= mintPrice * quantity, "Value is not enough");
        require(_numberMinted(msg.sender) + quantity <= maxMint, "Mint limit");
        require(_totalMinted() + quantity <= maxMintSupply, "SOLD OUT");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId();
            refundEndTimeStamp[tokenId] = block.timestamp + refundPeriod;
            _safeMint(msg.sender, 1);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    function refund(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Not the owner");
        require(block.timestamp <= refundEndTimeStamp[tokenId], "Refund period expired");
        require(!hasRefunded[tokenId], "Already refunded");

        hasRefunded[tokenId] = true;
        _burn(tokenId);
        Address.sendValue(payable(msg.sender), mintPrice);
    }

    function batchMint(uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= maxMintSupply, "SOLD OUT");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId();
            refundEndTimeStamp[tokenId] = block.timestamp + refundPeriod;
            _safeMint(msg.sender, 1);
        }
    }

    function extendRefundPeriod(uint256 tokenId, uint256 additionalTime) external onlyOwner {
        refundEndTimeStamp[tokenId] += additionalTime;
    }

    function setMaxMintSupply(uint256 newMaxMintSupply) external onlyOwner {
        maxMintSupply = newMaxMintSupply;
    }
}
