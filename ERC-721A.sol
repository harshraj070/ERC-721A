// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Placeholder for ERC721R and OpenZeppelin dependencies.
// Update these imports based on your project structure.
import "ERC721A.sol"; // Replace with the correct path to ERC721A
import "IERC721R.sol"; // Replace with the correct path to IERC721R
import "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Builder is ERC721A, Ownable {
    uint256 public constant mintPrice = 1 ether; // Cost per token
    uint256 public constant maxMint = 5;        // Max tokens per wallet
    uint256 public maxMintSupply = 100;         // Total supply limit
    uint256 public constant refundPeriod = 3 minutes; // Refund window duration

    address public refundAddress;

    mapping(uint256 => uint256) public refundEndTimeStamp;
    mapping(uint256 => bool) public hasRefunded;

    // Constructor to initialize the contract and set the refund address
    constructor(address initialOwner) ERC721A("Web3Builder", "MTK") Ownable() {
        refundAddress = address(this);
        transferOwnership(initialOwner);
    }

    // Returns the base URI for the token metadata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB/";
    }

    // Function for users to mint tokens
    function safeMint(uint256 quantity) public payable {
        require(msg.value >= mintPrice * quantity, "Value is not enough");
        require(_numberMinted(msg.sender) + quantity <= maxMint, "Mint limit exceeded");
        require(_totalMinted() + quantity <= maxMintSupply, "SOLD OUT");

        uint256 startTokenId = _nextTokenId();
        _safeMint(msg.sender, quantity);

        for (uint256 i = 0; i < quantity; i++) {
            refundEndTimeStamp[startTokenId + i] = block.timestamp + refundPeriod;
        }
    }

    // Function for the owner to withdraw contract funds
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Function for users to claim a refund
    function refund(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "Caller is not the token owner");
        require(block.timestamp <= refundEndTimeStamp[tokenId], "Refund period expired");
        require(!hasRefunded[tokenId], "Token already refunded");

        hasRefunded[tokenId] = true;
        _burn(tokenId);
        payable(msg.sender).transfer(mintPrice);
    }

    // Owner-only function for batch minting tokens
    function batchMint(uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= maxMintSupply, "SOLD OUT");

        uint256 startTokenId = _nextTokenId();
        _safeMint(msg.sender, quantity);

        for (uint256 i = 0; i < quantity; i++) {
            refundEndTimeStamp[startTokenId + i] = block.timestamp + refundPeriod;
        }
    }

    // Function to extend the refund period for a specific token
    function extendRefundPeriod(uint256 tokenId, uint256 additionalTime) external onlyOwner {
        refundEndTimeStamp[tokenId] += additionalTime;
    }

    // Function to modify the max mint supply
    function setMaxMintSupply(uint256 newMaxMintSupply) external onlyOwner {
        maxMintSupply = newMaxMintSupply;
    }
}
