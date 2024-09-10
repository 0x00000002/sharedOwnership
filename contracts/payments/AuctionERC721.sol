// SPDX-License-Identifier: MIT

pragma solidity ~0.8.26;

/* open source library for ERC1155 standard interface */
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Auction is AccessManaged {
    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        bool active;
    }

    IERC721 public nftContract;
    mapping(uint256 => Auction) public auctions;

    event AuctionCreated(uint256 indexed tokenId, uint256 endTime);
    event BidPlaced(uint256 indexed tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 amount);

    constructor(address manager, IERC721 _nftContract) AccessManaged(manager) {
        nftContract = _nftContract;
    }

    function createAuction(uint256 tokenId, uint256 duration) external {
        require(
            nftContract.ownerOf(tokenId) == msg.sender,
            "Not the token owner"
        );
        require(auctions[tokenId].active == false, "Auction already active");

        nftContract.transferFrom(msg.sender, address(this), tokenId);

        auctions[tokenId] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + duration,
            active: true
        });

        emit AuctionCreated(tokenId, block.timestamp + duration);
    }

    function placeBid(uint256 tokenId) external payable {
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

    function endAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            nftContract.transferFrom(
                address(this),
                auction.highestBidder,
                tokenId
            );
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            nftContract.transferFrom(address(this), auction.seller, tokenId);
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function withdraw(address to) external restricted {
        payable(to).transfer(address(this).balance);
    }
}
