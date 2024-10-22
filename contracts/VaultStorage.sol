// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./Asset.sol";
import "./Share.sol";
import "./IVault.sol";

/**
 * @notice Vault storage contract
 * @notice This contract is used by the Vault contract to store and retrieve data
 * @notice Only the Vault contract can write to this contract
 */
contract VaultStorage is IVault, AccessManaged {
    mapping(uint256 assetId => VaultStatus) public status;

    mapping(uint256 vaultId => Vault) public vaults;
    mapping(uint256 assetId => uint256 vaultId) public assetVaults;
    mapping(uint256 vaultId => uint256[] assetIds) public vaultAssets;
    mapping(uint256 poolId => Pool) public pools;
    mapping(uint256 poolId => mapping(address shareholder => uint256))
        public shares;

    constructor(address manager) AccessManaged(manager) {}

    function getPool(uint256 poolId) external view returns (Pool memory) {
        return pools[poolId];
    }

    function getVaultOwner(uint256 vaultId) external view returns (address) {
        return vaults[vaultId].owner;
    }

    function getVaultDebt(uint256 vaultId) external view returns (uint256) {
        return vaults[vaultId].poolsDebt;
    }

    function getVaultCollateral(
        uint256 vaultId
    ) external view returns (uint256) {
        return vaults[vaultId].collateral;
    }

    function getPoolDebt(uint256 poolId) external view returns (uint256) {
        return pools[poolId].debt;
    }

    function setVault(uint256 vaultId, Vault memory vault) external restricted {
        vaults[vaultId] = vault;
    }

    function setAsset(uint256 assetId, uint256 vaultId) external restricted {
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
            vaultAssets[vaultId].push(vaultId);
        }
    }

    function setPool(uint256 poolId, Pool memory pool) external restricted {
        pools[poolId] = pool;
    }
}
