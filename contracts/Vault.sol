// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./Asset.sol";
import "./Share.sol";

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

    mapping(address asset => address share) private _assetShares;
    mapping(uint256 assetId => uint256) private _periodsCount;
    mapping(uint256 assetId => mapping(uint256 periodId => Period))
        private _periods;

    event PairAdded(address indexed asset, address indexed share);
    event PeriodAdded(
        uint256 indexed assetId,
        uint256 indexed periodId,
        uint256 expectedReward,
        uint32 startTime,
        uint32 endTime
    );
    event PeriodOver(uint256 indexed assetId, uint256 indexed periodId);

    constructor(address manager) AccessManaged(manager) {}

    function addPair(address asset, address share) external restricted {
        _assetShares[asset] = share;
        emit PairAdded(asset, share);
    }

    function newPeriod(
        address asset,
        uint256 assetId,
        uint256 expectedReward,
        uint32 startTime,
        uint32 endTime
    ) external {
        require(_assetShares[asset] != address(0), "Vault: unknown asset");
        Period memory period = Period(
            assetId,
            expectedReward,
            startTime,
            endTime,
            false
        );
        _periods[assetId][_periodsCount[assetId]++] = period;
    }
}
