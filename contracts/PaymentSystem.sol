// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./SYNDToken.sol";

string constant CURRENCY = "NZD";

error InsufficientAmount(uint256 required, uint256 actual);

/**
 * @dev Payment System contract
 */
contract PaymentSystem is AccessManaged, ReentrancyGuard {
    enum Currency {
        NZD,
        ETH,
        ROOT,
        ASTO,
        XRP
    }
    struct Payment {
        address user;
        uint32 timestamp;
        uint256 amount;
        Currency currency;
    }

    uint256 private _syndicateRegistrationFee;
    uint256 public totalFees;

    mapping(uint256 syndicateId => uint256 priceForOne) public shareCost;
    mapping(uint256 syndicateId => uint256 currentlyIssuedShares)
        public sharesIssued;
    mapping(uint256 syndicateId => uint256 balance) public syndicateBalance;

    mapping(uint256 paymentId => Payment) public payments;

    mapping(address shareholder => mapping(Currency => uint256))
        public balances;

    constructor(address manager) AccessManaged(manager) {}

    function paySyndicateRegistrationFee() external payable {
        uint256 value = msg.value;
        require(
            value >= _syndicateRegistrationFee,
            InsufficientAmount(_syndicateRegistrationFee, value)
        );
        totalFees += value;
    }

    function paySharesNativeCurrency(
        uint256 syndicateId,
        uint256 amount
    ) external payable {
        uint256 value = msg.value;
        uint256 cost = shareCost[syndicateId] * amount;
        require(value >= cost, InsufficientAmount(cost, value));
    }

    function sellShares(uint256 purchaseId) external nonReentrant {
        // (bool sent, bytes memory data) = msg.sender.call{value: cost}("");
    }

    // !----------------------
    // ! Admin functions
    // !----------------------

    function setSyndicateRegistrationFee(uint256 fee) external restricted {
        _syndicateRegistrationFee = fee;
    }
}
