// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/**
 * @notice IVault
 * @notice Shared types of the Vault contracts.
 */
interface IVault {
    enum VaultStatus {
        Clear, // no assigned pools or unpaid debts,
        Locked, // Asset is in pool, period is active
        Undercollateralized, // collateral is less than the debt
        Liquidation // no payment received, collateral is in liquidation (under auction)
    }

    enum PoolStatus {
        Uncovered, // Pool is not covered by the collateral
        Active, // Pool is active, waiting for the end of the period,
        Finished, // Pool is finished, waiting for the reward distribution
        Overdue, // standard waiting period is over, waiting for the payment
        Paid, // Pool is paid (reward.actual >= reward.promised)
        Failed // Pool is failed (reward.actual < reward.promised)
    }

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

    enum TimeMultiplier {
        Linear,
        // Deposits  can be made throughout the reward period.
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

    struct Shares {
        uint256 max;
        uint256 wallets;
    }

    struct Reward {
        uint256 promised;
        uint256 actual;
        uint256 multiplicator;
        uint256 perShare;
        uint256 perUser;
        ROIType roi;
        DistributionScheme distribution;
        TimeMultiplier multiplier;
    }

    struct Conditions {
        uint32 startTime;
        uint32 endTime;
        uint32 minDuration;
        bool lateDeposits;
        bool earlyWithdrawals;
        uint256 minDeposit;
        uint256 maxDeposit;
    }

    struct Failure {
        uint256 debt;
        uint256 collateralLiquidationTotal;
        uint256 assetsLiquidationTotal;
        uint256 debtAfterLiquidation;
    }

    struct Pool {
        Shares shares;
        Reward reward;
        PoolStatus status;
        Conditions conditions;
    }

    struct Vault {
        address owner;
        VaultStatus status;
        uint256 collateral;
    }
}
