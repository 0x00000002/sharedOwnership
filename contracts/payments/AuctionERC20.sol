// SPDX-License-Identifier: MIT

pragma solidity ~0.8.26;

/* open source library for ERC1155 standard interface */
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts//utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Auction is AccessManaged, ReentrancyGuard {
    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        uint256 amount;
        bool active;
    }

    IERC20 public paymentToken;
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCounter;

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 amount,
        uint256 endTime
    );
    event BidPlaced(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionEnded(
        uint256 indexed auctionId,
        address winner,
        uint256 amount
    );

    constructor(address manager, IERC20 _paymentToken) AccessManaged(manager) {
        paymentToken = _paymentToken;
    }

    function createAuction(
        uint256 amount,
        uint256 duration
    ) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(
            paymentToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        auctionCounter++;
        uint256 auctionId = auctionCounter;

        auctions[auctionId] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + duration,
            amount: amount,
            active: true
        });

        emit AuctionCreated(auctionId, amount, block.timestamp + duration);
    }

    function placeBid(
        uint256 auctionId,
        uint256 bidAmount
    ) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(bidAmount > auction.highestBid, "Bid too low");

        if (auction.highestBidder != address(0)) {
            require(
                paymentToken.transfer(
                    auction.highestBidder,
                    auction.highestBid
                ),
                "Refund failed"
            );
        }

        require(
            paymentToken.transferFrom(msg.sender, address(this), bidAmount),
            "Token transfer failed"
        );

        auction.highestBidder = msg.sender;
        auction.highestBid = bidAmount;

        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }

    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction not active");
        require(block.timestamp >= auction.endTime, "Auction not ended");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            require(
                paymentToken.transfer(auction.seller, auction.highestBid),
                "Payment to seller failed"
            );
            // Transfer the auctioned amount of tokens to the highest bidder
            require(
                paymentToken.transfer(auction.highestBidder, auction.amount),
                "Token transfer to winner failed"
            );
        } else {
            // If there were no bids, return the tokens to the seller
            require(
                paymentToken.transfer(auction.seller, auction.amount),
                "Token return to seller failed"
            );
        }

        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    function withdraw(address to) external restricted nonReentrant {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(paymentToken.transfer(to, balance), "Withdraw failed");
    }
}
