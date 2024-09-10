// SPDX-License-Identifier: MIT

pragma solidity ~0.8.26;

/* open source library for ERC1155 standard interface */
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts//utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ERC1155Auction is AccessManaged, ReentrancyGuard {
    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        uint256 amount;
        bool active;
    }

    IERC1155 public nftContract;
    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 amount,
        uint256 endTime
    );
    event BidPlaced(uint256 indexed tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 amount);

    constructor(address manager, IERC1155 _nftContract) AccessManaged(manager) {
        nftContract = _nftContract;
    }

    function createAuction(
        uint256 tokenId,
        uint256 amount,
        uint256 duration
    ) external nonReentrant {
        require(
            nftContract.balanceOf(msg.sender, tokenId) >= amount,
            "Not enough tokens owned"
        );
        require(auctions[tokenId].active == false, "Auction already active");

        nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );

        auctions[tokenId] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + duration,
            amount: amount,
            active: true
        });

        emit AuctionCreated(tokenId, amount, block.timestamp + duration);
    }

    function placeBid(uint256 tokenId) external payable nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid, "Bid too low");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            nftContract.safeTransferFrom(
                address(this),
                auction.highestBidder,
                tokenId,
                auction.amount,
                ""
            );
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            nftContract.safeTransferFrom(
                address(this),
                auction.seller,
                tokenId,
                auction.amount,
                ""
            );
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function withdraw(address to) external restricted nonReentrant {
        payable(to).transfer(address(this).balance);
    }

    // Required to handle the receipt of ERC1155 tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
