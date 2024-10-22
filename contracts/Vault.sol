// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Asset.sol";
import "./Share.sol";
import "./IVault.sol";
import "./VaultStorage.sol";

/**
 * @notice Vault contract
 * @notice This contract is responsible for managing assets, its collaterals, and shares pool,
 * @notice with a specific reward distribution mechanism.
 * @notice At the end of the period, pool receives reward and distribute it to its contributors.
 */
contract Vault is IVault, ReentrancyGuard, AccessManaged {
    Asset private _asset;
    Share private _share;
    VaultStorage private _storage;

    mapping(uint256 assetId => VaultStatus) private _status;

    uint256 private _poolsCount; // counter for pools, starts from 1
    uint256 private _vaultsCount; // counter for vaults, starts from 1

    mapping(uint256 vaultId => mapping(uint256 poolId => Pool)) private _pools;
    mapping(uint256 poolId => mapping(address shareholder => uint256))
        private _shares;

    error PoolError(string message, uint256 assetId, uint256 poolId);
    error VaultAccessError(
        string message,
        uint256 vaultId,
        address owner,
        address caller
    );

    event PoolSet(
        uint256 indexed vaultId,
        Reward indexed reward,
        uint256 poolId,
        uint32 startTime,
        uint32 endTime
    );

    event VaultCreated(uint256 indexed vaultId, address indexed owner);
    event PoolReward(string message, uint256 indexed poolId, uint256 amount);

    constructor(
        address vaultStorage,
        address asset,
        address share,
        address manager
    ) AccessManaged(manager) {
        _storage = VaultStorage(vaultStorage);
        _asset = Asset(asset);
        _share = Share(share);
    }

    function newVault() external nonReentrant returns (uint256 vaultId) {
        vaultId = ++_vaultsCount; // vaultId starts from 1
        address msgSender = msg.sender;
        _storage.setVault(
            vaultId,
            Vault({
                owner: msgSender,
                status: VaultStatus.Locked,
                collateral: 0,
                poolsDebt: 0,
                pools: new uint256[](0)
            })
        );
        emit VaultCreated(vaultId, msgSender);
    }

    function lockAsset(
        uint256[] memory assetIds,
        uint256 vaultId
    ) external nonReentrant {
        address caller = msg.sender;
        address vaultOwner = _storage.getVaultOwner(vaultId);
        require(
            vaultOwner == caller,
            VaultAccessError("Not a vault owner", vaultId, vaultOwner, caller)
        );
        for (uint256 i = 0; i < assetIds.length; i++) {
            uint256 assetId = assetIds[i];
            address assetOwner = _asset.ownerOf(assetId);
            require(
                caller == assetOwner,
                VaultAccessError(
                    "Not an asset owner",
                    vaultId,
                    assetOwner,
                    caller
                )
            );
            _asset.transferFrom(caller, address(this), assetId);
            _storage.setAsset(assetId, vaultId);
        }
    }

    function unlockAsset(uint256 assetId) public {
        uint256 vaultId = _storage.assetVaults(assetId);
        address caller = msg.sender;
        address vaultOwner = _storage.getVaultOwner(vaultId);
        require(
            vaultOwner == caller,
            VaultAccessError("Not a vault owner", vaultId, vaultOwner, caller)
        );

        // TODO: check if the asset is not locked in the pool

        _storage.setAsset(assetId, 0);
        _asset.transferFrom(address(this), caller, assetId);
    }

    function setPool(
        uint256 vaultId,
        Reward memory reward,
        uint32 startTime,
        uint32 endTime
    ) public {
        _setPool(++_poolsCount, vaultId, startTime, endTime, reward);
    }

    function setPool(
        uint256 poolId,
        uint256 vaultId,
        Reward memory reward,
        uint32 startTime,
        uint32 endTime
    ) public {
        // todo: check the vault owner (poolId)
        _setPool(poolId, vaultId, startTime, endTime, reward);
    }

    function _setPool(
        uint256 poolId,
        uint256 vaultId,
        uint32 startTime,
        uint32 endTime,
        Reward memory reward
    ) private {
        Pool memory pool = Pool({
            shares: 0,
            debt: 0,
            reward: reward,
            startTime: startTime,
            endTime: endTime
        });
        _storage.setPool(poolId, pool);
        emit PoolSet(vaultId, reward, poolId, startTime, endTime);
    }

    function loadReward(uint256 poolId, uint256 amount) public payable {
        Pool memory pool = _storage.getPool(poolId);
        require(
            pool.startTime < block.timestamp,
            PoolError("Pool is not open", 0, poolId)
        );

        emit PoolReward("Reward added", poolId, amount);
    }

    function isFree(uint256 vaultId) public view returns (bool) {
        return _storage.getVaultDebt(vaultId) == 0;
    }
}
