// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // TODO: switch to transient storage reentrancy guard
import "./Asset.sol";
import "./Share.sol";
import "./IVault.sol";

/**
 * @notice Vault storage contract
 * @notice This contract is used by the Vault contract to store and retrieve data
 * @notice Only the Vault contract can write to this contract
 */

contract VaultStorage is IVault, ReentrancyGuard, AccessManaged {
    mapping(bytes32 vaultId => Vault) public vaults; // vaultId = keccak256(owner, vaultCount)
    mapping(uint256 assetId => bytes32 vaultId) public assetVaults;
    mapping(bytes32 vaultId => uint256[] assetIds) public vaultAssets;

    mapping(bytes32 vaultId => mapping(uint256 poolId => Pool)) public pools;
    mapping(bytes32 vaultId => uint256[]) public failureIds;
    mapping(bytes32 vaultId => mapping(uint256 poolId => Failure))
        public failures;

    constructor(address manager) AccessManaged(manager) {}

    function getPool(
        bytes32 vaultId,
        uint256 poolId
    ) external view returns (Pool memory) {
        return pools[vaultId][poolId];
    }

    function getVault(bytes32 vaultId) external view returns (Vault memory) {
        return vaults[vaultId];
    }

    function getFailure(
        bytes32 vaultId,
        uint256 poolId
    ) external view returns (Failure memory) {
        return failures[vaultId][poolId];
    }

    function getVaultOwner(bytes32 vaultId) external view returns (address) {
        return vaults[vaultId].owner;
    }

    function getVaultAssets(
        bytes32 vaultId
    ) external view returns (uint256[] memory) {
        return vaultAssets[vaultId];
    }

    function getVaultCollateral(
        bytes32 vaultId
    ) external view returns (uint256) {
        return vaults[vaultId].collateral;
    }

    function getVaultStatus(
        bytes32 vaultId
    ) external view returns (VaultStatus) {
        return vaults[vaultId].status;
    }

    function updateVaultStatus(
        bytes32 vaultId,
        VaultStatus _status
    ) external restricted {
        Vault storage vault = vaults[vaultId];
        vault.status = _status;
    }

    function setVault(
        bytes32 vaultId,
        Vault memory vault
    )
        external
        nonReentrant // TODO: switch to transient storage reentrancy guard
        restricted
    {
        vaults[vaultId] = vault;
    }

    function setPool(
        bytes32 vaultId,
        uint256 poolId,
        Pool memory pool
    )
        external
        nonReentrant // TODO: switch to transient storage reentrancy guard
        restricted
    {
        pools[vaultId][poolId] = pool;
    }

    function setAssets(
        uint256[] memory assetIds,
        bytes32 vaultId
    )
        external
        nonReentrant // TODO: switch to transient storage reentrancy guard
        restricted
    {
        for (uint256 j = 0; j < assetIds.length; j++) {
            uint256 assetId = assetIds[j];
            bool inVault = assetVaults[assetId] > 0;
            if (inVault) {
                uint256[] storage assets = vaultAssets[vaultId];
                uint256 length = assets.length;
                for (uint256 i = 0; i < length; i++) {
                    if (assets[i] == assetId) {
                        assets[i] = assets[length - 1];
                        assets.pop();
                        break;
                    }
                }
                assetVaults[assetId] = 0;
            } else {
                assetVaults[assetId] = vaultId;
                vaultAssets[vaultId].push(assetId);
            }
        }
    }

    function requireUnlockedVault(bytes32 vaultId) public view {
        require(vaults[vaultId].status == VaultStatus.Clear, "Vault is locked");
    }
}
