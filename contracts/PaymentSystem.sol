// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import "./SYNDToken.sol";

string constant CURRENCY = "NZD";

error InsufficientAmount(uint256 required, uint256 actual);

event RegistrationFeePaid(address indexed payer, bytes32 indexed syndicateId, uint256 amount);

/**
 * @dev Payment System contract
 */
contract PaymentSystem is AccessManaged {
    uint256 private _syndicateRegistrationFee;

    uint256 public totalFees;

    mapping(bytes32 syndicateId => uint256) public shareCost;


    constructor(address manager) AccessManaged(manager) {}

    function paySyndicateRegistrationFee(bytes32 syndicateId) external payable {
        uint256 value = msg.value;
        require(
            value >= _syndicateRegistrationFee,
            InsufficientAmount(_syndicateRegistrationFee, value)
        );
        totalFees += value;

        emit RegistrationFeePaid(msg.sender, syndicateId, value);
    }
}
