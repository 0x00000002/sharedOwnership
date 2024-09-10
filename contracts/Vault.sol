// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

/**
 * @dev Asset token contract
 */
contract Vault is AccessManaged {
    struct Period {
        uint256 assetId;
        uint256 expectedReward;
        uint32 startTime;
        uint32 endTime;
        bool isOver;
    }

    constructor(address manager) AccessManaged(manager) {}
}
