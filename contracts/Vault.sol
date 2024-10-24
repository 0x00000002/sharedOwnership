// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Asset.sol";
import "./Share.sol";
import "./IVault.sol";
import "./VaultStorage.sol";

error PoolError(string message, uint256 requiredAmount);
error VaultAccessError(
    string message,
    bytes32 vaultId,
    address owner,
    address caller
);

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

    mapping(address user => uint256) private _vaultCount; // how many vaults a user has
    mapping(bytes32 vaultId => uint256) private _poolCount; // how many pools a vault has

    event VaultCreated(
        address indexed owner,
        uint256 vaultNumber,
        uint32 timestamp,
        bytes32 vaultId
    );
    event PoolRewarded(
        string indexed message,
        uint256 indexed poolId,
        uint256 amount
    );
    event PoolSet(
        bytes32 indexed vaultId,
        uint256[] indexed assetIds,
        Reward reward,
        uint256 poolId,
        uint32 startTime,
        uint32 endTime,
        PoolStatus status
    );

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

    function newVault() external returns (bytes32 vaultId) {
        address caller = msg.sender;
        uint32 timestamp = uint32(block.timestamp);
        uint256 vaultCount = _vaultCount[caller]++;
        vaultId = keccak256(abi.encodePacked(caller, timestamp, vaultCount));
        address owner = _storage.getVaultOwner(vaultId);
        require(
            owner == address(0),
            VaultAccessError("Vault already exists", vaultId, owner, caller)
        );
        _storage.setVault(
            vaultId,
            Vault({owner: caller, status: VaultStatus.Clear, collateral: 0})
        );
        emit VaultCreated(caller, vaultCount, timestamp, vaultId);
    }

    function lockAssets(bytes32 vaultId, uint256[] memory assetIds) external {
        address caller = msg.sender;
        address vaultOwner = _storage.getVaultOwner(vaultId);
        require(
            vaultOwner == caller,
            VaultAccessError("Not a vault owner", vaultId, vaultOwner, caller)
        );
        for (uint256 i = 0; i < assetIds.length; i++) {
            _asset.transferFrom(caller, address(this), assetIds[i]);
        }
        _storage.setAssets(assetIds, vaultId);
    }

    function unlockAssets(bytes32 vaultId, uint256[] memory assetIds) public {
        address caller = msg.sender;
        address vaultOwner = _storage.getVaultOwner(vaultId);
        require(
            _storage.getVaultStatus(vaultId) == VaultStatus.Clear,
            VaultAccessError("Vault is locked", vaultId, vaultOwner, caller)
        );
        for (uint256 i = 0; i < assetIds.length; i++) {
            require(
                vaultOwner == caller,
                VaultAccessError(
                    "Not a vault owner",
                    vaultId,
                    vaultOwner,
                    caller
                )
            );
            _asset.transferFrom(address(this), vaultOwner, assetIds[i]);
        }
        _storage.setAssets(assetIds, vaultId);
    }

    function addPool(
        bytes32 vaultId,
        Reward memory reward,
        Conditions memory conditions
    ) public {
        address caller = msg.sender;
        address valtOwner = _storage.getVaultOwner(vaultId);
        require(
            valtOwner == caller,
            VaultAccessError("Not a vault owner", vaultId, valtOwner, caller)
        );
        uint256 poolId = _poolCount[vaultId]++;
        _setPool(vaultId, poolId, reward, conditions);
    }

    function setPool(
        bytes32 vaultId,
        uint256 poolId,
        Reward memory reward,
        Conditions memory conditions
    ) public {
        address caller = msg.sender;
        address valtOwner = _storage.getVaultOwner(vaultId);
        require(
            valtOwner == caller,
            VaultAccessError("Not a vault owner", vaultId, valtOwner, caller)
        );
        _setPool(vaultId, poolId, reward, conditions);
    }

    function _setPool(
        bytes32 vaultId,
        uint256 poolId,
        Reward memory reward,
        Conditions memory conditions
    ) private {
        VaultStatus vaultStatus = refreshVaultStatus(vaultId);
        PoolStatus poolStatus = vaultStatus == VaultStatus.Undercollateralized
            ? PoolStatus.Uncovered
            : PoolStatus.Active;
        Shares memory shares = Shares({max: 0, wallets: 0});

        Pool memory pool = Pool({
            shares: shares,
            reward: reward,
            conditions: conditions,
            status: poolStatus
        });

        _storage.setPool(vaultId, poolId, pool);
        uint256[] memory assetIds = _storage.getVaultAssets(vaultId);

        emit PoolSet(
            vaultId,
            assetIds,
            reward,
            poolId,
            conditions.startTime,
            conditions.endTime,
            poolStatus
        );
    }

    /**
     * This function checks the vault collateral,
     * calculate the sum of promised rewards for all vault's pools,
     * and check if the sum is less than the collateral.
     * If so, set the vault status to Undercollateralized, otherwise to Active.
     * @param vaultId - vault id
     * @return vaultStatus
     */
    function refreshVaultStatus(bytes32 vaultId) public returns (VaultStatus) {
        Vault memory vault = _storage.getVault(vaultId);
        uint256 totalPromisedRewards = 0;

        for (uint256 i = 0; i < _poolCount[vaultId]; i++) {
            totalPromisedRewards += _storage
                .getPool(vaultId, i)
                .reward
                .promised;
        }
        if (totalPromisedRewards > vault.collateral) {
            vault.status = VaultStatus.Undercollateralized;
        } else {
            vault.status = VaultStatus.Locked;
        }
        _storage.setVault(vaultId, vault);
        return vault.status;
    }

    function loadReward(bytes32 vaultId, uint256 poolId) public payable {
        uint256 amount = msg.value;
        Pool memory pool = _storage.getPool(vaultId, poolId);

        require(
            pool.conditions.startTime < block.timestamp,
            PoolError("Pool is not open", poolId)
        );

        pool.reward.actual += amount;

        if (pool.reward.actual >= pool.reward.promised) {
            pool.status = PoolStatus.Paid;
            emit PoolRewarded("Promise fulfilled", poolId, pool.reward.actual);
        } else {
            emit PoolRewarded("Some reward added", poolId, amount);
        }
        _storage.setPool(vaultId, poolId, pool);
    }

    function participate(bytes32 vaultId, uint256 poolId) public payable {
        uint256 amount = msg.value;
        Pool memory pool = _storage.getPool(vaultId, poolId);
        require(amount > 0, PoolError("Value must be greater than", 0));
        (
            uint32 startTime,
            uint32 endTime,
            bool lateDeposits,
            uint256 minDeposit,
            uint256 maxDeposit
        ) = (
                pool.conditions.startTime,
                pool.conditions.endTime,
                pool.conditions.lateDeposits,
                pool.conditions.minDeposit,
                pool.conditions.maxDeposit
            );
        if (pool.conditions.maxDeposit > 0) {
            require(amount <= maxDeposit, PoolError("MaxDeposit:", minDeposit));
        }
        require(amount >= minDeposit, PoolError("MinDeposit", minDeposit));

        require(
            block.timestamp < endTime,
            PoolError("No deposits after end:", uint256(endTime))
        );

        if (!lateDeposits) {
            require(
                block.timestamp < startTime,
                PoolError("No deposits after start:", uint256(startTime))
            );
        }
        pool.status = PoolStatus.Active;
        pool.shares.max += amount;
        _storage.setPool(vaultId, poolId, pool);

        _share.mint(msg.sender, poolId, amount);
    }

    function getReward(
        bytes32 vaultId,
        uint256 poolId
    )
        public
        nonReentrant // TODO: switch to transient storage reentrancy guard
    {
        address shareholder = msg.sender;
        Pool memory pool = _storage.getPool(vaultId, poolId);
        (uint32 startTime, uint32 endTime, bool earlyWithdrawals) = (
            pool.conditions.startTime,
            pool.conditions.endTime,
            pool.conditions.earlyWithdrawals
        );

        uint256 userReward = 0;

        require(
            block.timestamp > startTime,
            PoolError("Pool's period is not started", uint256(startTime))
        );

        if (earlyWithdrawals == false) {
            require(
                block.timestamp > endTime,
                PoolError("Pool's period is not over", uint256(endTime))
            );
        }

        uint256 shares = _share.balanceOf(shareholder, poolId);
        _share.burn(shareholder, poolId, shares);
        _storage.setPool(vaultId, poolId, pool);

        if (pool.reward.perShare > 0) {
            userReward = shares * pool.reward.perShare;
        } else if (pool.reward.perUser > 0) {
            userReward = pool.reward.perUser;
        } else {
            calculateReward(pool);
        }

        payable(msg.sender).transfer(userReward);
    }

    function calculateReward(
        Pool memory pool
    ) public pure returns (Pool memory updatedPool) {
        if (pool.reward.distribution == DistributionScheme.ContributionBased) {
            updatedPool.reward.perShare =
                pool.reward.promised /
                pool.shares.max;
        } else if (pool.reward.distribution == DistributionScheme.ProRata) {
            updatedPool.reward.perShare = pool.reward.actual / pool.shares.max;
        } else if (pool.reward.distribution == DistributionScheme.EqualShare) {
            updatedPool.reward.perUser =
                pool.reward.actual /
                pool.shares.wallets;
        }
        return updatedPool;
    }
}
