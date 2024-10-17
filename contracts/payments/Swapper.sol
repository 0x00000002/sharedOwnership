// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @dev Payment System - Token swapping contract
 */
contract Swapper is AccessManaged, ReentrancyGuard {
    constructor(address manager) AccessManaged(manager) {}

    // !----------------------
    // ! Admin functions
    // !----------------------
}
