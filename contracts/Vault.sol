// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./Asset.sol";
import "./Share.sol";

/**
 * @dev Asset token contract
 */
contract Vault is AccessManaged {
    struct Period {
        uint32 startTime;
        uint32 endTime;
        bool isOver;
    }

    enum PoolType {
        ContributionBased,
        VolumeProportioned,
        VolumeTimeProportioned
    }

    struct Pool {
        PoolType poolType;
        Period period;
        uint256 assetId;
        uint256 expectedReward;
    }
    // struct FixedRewardPool {
    //     // VaultType vaultType;
    //     Period period;
    //     uint256 assetId;
    //     uint256 expectedReward;
    // }

    // struct VolumeProportionedPool {
    //     // VaultType vaultType;
    //     Period period;
    //     uint256 assetId;
    //     uint256 expectedReward;
    // }

    // struct VolumeTimeProportionedPool {
    //     Period period;
    //     uint256 assetId;
    //     uint256 expectedReward;
    // }

    Asset private _asset;
    Share private _share;

    mapping(uint256 assetId => uint256) private _periodsCount;
    mapping(uint256 assetId => mapping(uint256 periodId => Period))
        private _periods;

    event PeriodAdded(
        uint256 indexed assetId,
        uint256 indexed periodId,
        uint256 expectedReward,
        uint32 startTime,
        uint32 endTime
    );
    event PeriodOver(uint256 indexed assetId, uint256 indexed periodId);

    constructor(
        address asset,
        address share,
        address manager
    ) AccessManaged(manager) {
        _asset = Asset(asset);
        _share = Share(share);
    }

    function newPeriod(
        uint256 assetId,
        uint32 startTime,
        uint32 endTime
    ) external {
        Period memory period = Period(startTime, endTime, false);
        _periods[assetId][_periodsCount[assetId]++] = period;
    }

    function newVault(
        uint256 assetId,
        uint256 periodId,
        PoolType poolType
    ) external {}
}
