// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

error InsufficientAmount(uint256 required, uint256 actual);

/**
 * @dev Payment System - Paayment processor contract
 */
contract PaymentProcessor is AccessManaged, ReentrancyGuard {
    enum Currency {
        XRP,
        ROOT,
        ASTO,
        SYLO
    }

    enum Fee {
        OwnerRegistration,
        AssetRegistration,
        SharePurchase,
        ShareSale
    }
    struct Payment {
        address user;
        uint32 timestamp;
        uint256 amount;
        Currency currency;
    }

    mapping(Fee => uint256) private _totalFeesCollected;

    mapping(uint256 syndicateId => uint256 priceForOne) public shareCost;
    mapping(uint256 syndicateId => uint256 currentlyIssuedShares)
        public sharesIssued;
    mapping(uint256 syndicateId => uint256 balance) public syndicateBalance;

    mapping(uint256 paymentId => Payment) public payments;

    mapping(address shareholder => mapping(Currency => uint256))
        public balances;

    mapping(Fee => uint256) _fees;

    event FeeCollected(
        Fee indexed feeType,
        Currency indexed currencyType,
        uint256 value
    );

    constructor(address manager) AccessManaged(manager) {}

    /**
     * @notice Pay fee
     * @notice currently it supports payments in native currency only
     * @dev feeType - the type of fee to pay
     */
    function payFee(Currency currency, Fee feeType) external payable {
        uint256 value;
        uint256 fee = _fees[feeType];
        if (currency == PaymentProcessor.Currency.XRP) {
            value = msg.value;
            require(value >= fee, InsufficientAmount(fee, value));
        } else {
            revert("Method is not supported yet");
        }

        emit FeeCollected(feeType, currency, value);
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

    function setFee(Fee fee, uint256 amount) external restricted {
        _fees[fee] = amount;
    }

    function withdawFees(
        address payable to,
        uint256 amount
    ) external restricted {
        to.call{value: amount};
    }
}
