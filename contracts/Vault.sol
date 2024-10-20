// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./Asset.sol";
import "./Share.sol";

/**
 * @notice Vault contract
 * @notice This contract is responsible for managing assets, its collaterals, and shares pool,
 * @notice with a specific reward distribution mechanism.
 * @notice At the end of the period, pool receives reward and distribute it to its contributors.
 */
contract Vault is AccessManaged {
    Asset private _asset;
    Share private _share;

    enum ROIType {
        Multiplicative,
        // The total reward pool is increased by a multiplier based on deposits.

        Fixed,
        // A fixed reward to be assigned and distributed among contributors.

        NonGuaranteed
        // An expected reward that is not guaranteed,
        // to be assigned and distributed among contributors.
    }

    enum DistributionScheme {
        EqualShare,
        // Each contributor receives the same reward amount,
        // regardless of the size of their contribution.

        ContributionBased,
        // Rewards are determined by the absolute size of each contribution,
        // not by the contributor's share of the total pool.

        ProRata
        // Rewards are distributed in proportion to each user's share of the total pool.
    }

    enum DurationMultiplier {
        Upfront,
        // All deposits must be made before the reward period begins.
        // No multiplier is applied to the reward.

        Linear,
        // Deposits can be made throughout the reward period.
        // Rewards are distributed proportionally based on the timing of contributions.
        // The total reward is divided across the entire period,
        // with earlier contributions receiving a larger share.
        // As the period progresses, the reward for new contributions decreases.

        FrontLoaded,
        // Deposits can be made throughout the reward period.
        // Contributions made earlier in the period receive a higher reward multiplier.
        // The reward multiplier starts high at the beginning of the period (X)
        // and decreases linearly to a lower value (Y) by the end of the period.

        BackLoaded
        // Deposits can be made throughout the reward period.
        // Contributions made later in the period receive a higher reward multiplier.
        // The reward multiplier starts low at the beginning of the period (X)
        // and increases linearly to a higher value (Y) by the end of the period.
    }
    struct Reward {
        uint256 expectedTotal;
        ROIType roi;
        DistributionScheme distribution;
        DurationMultiplier multiplier;
    }

    struct Pool {
        address owner;
        uint32 startTime;
        uint32 endTime;
        Reward reward;
    }

    uint256 private _poolsCount;

    mapping(uint256 assetId => uint256 poolId) private _assets;
    mapping(uint256 poolId => mapping(address shareholder => uint256)) _shares;
    mapping(uint256 poolId => uint256) private _poolShares;
    mapping(uint256 poolId => Pool) private _pools;
    mapping(uint256 poolId => uint256) private _rewards;

    error PoolError(string message, uint256 assetId, uint256 poolId);

    event PoolSet(
        uint256 indexed assetId,
        Reward indexed reward,
        uint256 poolId,
        uint32 startTime,
        uint32 endTime
    );

    event PoolReward(string message, uint256 indexed poolId, uint256 amount);

    constructor(
        address asset,
        address share,
        address manager
    ) AccessManaged(manager) {
        _asset = Asset(asset);
        _share = Share(share);
    }

    function unlockAsset(uint256 assetId) public {
        uint256 poolId = _assets[assetId];

        // TODO: check if the pool was rewarded

        delete _pools[poolId];
        delete _assets[assetId];

        _asset.setStatus(assetId, Asset.Status.Clear);
    }

    function setPool(
        uint256 assetId,
        Reward memory reward,
        uint32 startTime,
        uint32 endTime
    ) public {
        require(
            _assets[assetId] == 0,
            PoolError("Already in the pool", assetId, _assets[assetId])
        );
        _setPool(_poolsCount++, assetId, startTime, endTime, reward);
    }

    function setPool(
        uint256 poolId,
        uint256 assetId,
        Reward memory reward,
        uint32 startTime,
        uint32 endTime
    ) public {
        require(
            _assets[assetId] == poolId,
            PoolError("Asset is NOT in the pool", assetId, poolId)
        );
        _setPool(poolId, assetId, startTime, endTime, reward);
    }

    function _setPool(
        uint256 poolId,
        uint256 assetId,
        uint32 startTime,
        uint32 endTime,
        Reward memory reward
    ) private {
        _pools[poolId] = Pool(startTime, endTime, reward);
        _assets[assetId] = poolId;
        _asset.setStatus(assetId, Asset.Status.Locked);
        emit PoolSet(assetId, reward, poolId, startTime, endTime);
    }

    function loadReward(uint256 poolId, uint256 amount) public payable {
        Pool storage pool = _pools[poolId];
        require(
            pool.startTime < block.timestamp,
            PoolError("Pool is not open", 0, poolId)
        );

        emit PoolReward("Reward added", poolId, amount);
    }
}
