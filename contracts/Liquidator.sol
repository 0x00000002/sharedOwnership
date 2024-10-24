// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Vault.sol";

/**
 * @dev Payment System - Token swapping contract
 */
contract Liquidator is AccessManaged, ReentrancyGuard {
    Vault public vault;

    event Liquidated(
        bytes32 indexed vaultId,
        uint256 indexed poolId,
        uint256 indexed collateralId,
        uint256 amountEarned
    );

    constructor(address manager, address _vault) AccessManaged(manager) {
        vault = Vault(_vault);
    }

    function liquidateXRP(
        bytes32 vaultId,
        uint256 poolId,
        uint256 collateralIndex
    ) external payable returns (bool) {
        vault.loadReward{value: msg.value}(vaultId, poolId);
        emit Liquidated(vaultId, poolId, collateralIndex, msg.value);
        return true;
    }

    // !----------------------
    // ! Admin functions
    // !----------------------
}
