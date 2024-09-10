# Participation token

## Problem statement

**Some** people are interested in the benefits of having a horse but cannot afford to own one due to financial constraints, lack of experience, or time limitations.

On a number of occasions, a part owner of a horse wants to sell their share in the horse but can’t due to not having the marketplace to do so.

There is a way to overcome some of these issues through ownership in syndicates, but it is still too complicated, requires individual ownership registration for each horse with the custodial authorities, and duplicated legal registration paperwork.

## Goals

Provide easy access to "shared ownership" where users can buy or sell “temporary ownership” tokens online. Their participation may be rewarded if the horse generates revenue. The ownership is confirmed in a decentralized, trustless manner.

These use case options should be present in any of the contracts. The reason for this is that the ASSET producer can have an option to record their intent or purpose for the horse. As each of the periods of a young horse are known, the ASSET producer can then attribute a cost estimate for that period, which would mean that the cost of the period could be established, with the proviso that if the costs were exceeded, then the ASSET purchaser would have to provide a top up. Just means we can manage the costs through another option.

## Proposed solution

Blockchain backed solution for transparency and trustworthiness, with Frontend to simplify access.

The blockchain part of the application will use the following terms:

- Asset token to digitize the real animals.
- Syndicate Token (ASSET), representing syndicated assets.
- Syndicate Registry to manage the [KYCed entities](https://www.notion.so/Syndicate-Token-ASSET-875367c0c34644d4b1f810377a794304?pvs=21), syndicate rules, and conditions of syndicate membership.
- Payment System, ensuring that rewards/ revenue is distributed to the user’s wallets.

## Business requirements

### Use case

It is similar to Racehorses, but instead of race horses participations, with no costs associated, users “lock in” in scheduled costs sharing in exchange for any revenue generated during the period, apart of breeding.

**Money flow:**

1. Syndicate owners evaluate their spending and potential revenue on a monthly or quarterly basis. These figures are set as targets.
2. The total costs of the syndicate are distributed among the shareholders proportionally to their share ownership.
3. Shareholders can choose to exchange a portion of the costs with anyone willing to cover those costs in exchange for future revenue. To do this, the shareholder locks the desired amount of ASSETs in the Vault, and others can add their funds (tokens) to the Vault and receive shares of that pool.
4. When the period ends, the syndicate deposits the actual earnings from the horse into the Vault, and the ASSETs are unlocked. Users can then claim their revenue by burning their ASSET shares.
5. Users can decide if they want to participate in that pool/syndicate basing on two parameters:

   - Horse performance: historical data on the number of races won
   - Syndicate honesty: comparison of earned rewards (external sources, e.g. horse racing results tables) versus deposited to the reward pool

   The horse's performance is unpredictable, making it a game element. However, the syndicate's honesty can be verified, even automated, using oracles.

### Supported currencies

Payments in various tokens should be supported, e.g. XRP (native currency of the Root Network), SYLO, ASTO, ROOT. This may necessitate the integration with decentralized exchanges, like Uniswap.

### Legal requirements

All users must be KYC verified. Asset/share tokens cannot be transferred to the non-KYC-verified account.

## Technical requirements

### Token extendibility

To guarantee the completeness of information regarding the main asset of Syndicate (the horse), the token representing the animal should be "extendable" in terms of data it contains. We can use a Dynamic Metadata registry (external project, out of scope of this one) for asset tokens to ensure:

- a fast start for this project, and
- the ability to introduce changes in the future.

### Metadata

We want to store assets metadata (where applicable, e.g. asset tokens) on IPFS and use CIDv1 to make it future proof.

### Upgradeability

All smart contracts should have dedicated storage to ensure future logic upgrades. Additionally, storage can also have a composite structure. Designing the logic to manage syndicates in advance can be challenging. The approach should either be as abstract as possible or made upgradeable.

## Architecture

Birds’ eye view, we will have 3 layers of smart contracts\*:

- Tokens
  - Asset: a token representing the ownership of the asset
  - PART: a token of participation in costs in exchange for profit
- Business logic
  - Users Registry - to manage users and issue ASSETs
  - Vault contract - to manage user deals
  - Collateral registry contract - to deposit/lock collateral assets
- Payment system
  - Payments: deposits/withdrawals
  - Auction system - to sell collateral assets for unpaid shares
  - Swapper - an interface to (external) decentralized exchanges, e.g. Uniswap, to swap payment and collateral tokens

---

\* - Each contract, in turn, can have its own storage, and thus consist of two or more SHAREs.

![part_token](/docs/part_token.png)

## Business logic

### Tokens

#### ASSET

A token representing the ownership of the asset. ASSETs are minted to the syndicate members in proportion to their ownership of the syndicate. The actual shares are held by the KYC team, who have permission to sell them in order to fulfil the syndicate’s promises.

The maintenance costs are evenly distributed among all ASSETs.

- Shareholders
  lock any amount of their ASSETs for a specific period. Tokens are automatically unlocked when the period ends AND reward is transferred from the syndicate to the Vault contract, to be claimed by Web3 users.

#### PART

A token that represents a share of the costs in exchange for a portion of the profits.
The ASSETs transferred to the Vault represent the costs for a specific period. Web3 users can pay any amount towards those costs and receive tokens representing their share of the cost pool in return.

When the period ends, the syndicate must transfer the share of the profit (in proportion to the ASSETs in the Vault compared to the total amount of ASSETs) to unlock the ASSETs.

Web3 users can then claim the profit in the Vault, and their SHAREs for that period will be burned.

- Syndicate managers
  - Set the predicted costs of the upcoming period.
  - Deposit (the proportion of) the syndicate’s earned profit into the Vault after the period ends.
- Syndicate shareholders
  - Transfer their ASSETs into the Vault for a specific period. Those ASSETs are locked until the syndicate managers deposit reward into the Vault.
- Web3 users
  - Deposit funds into the Vault and receive SHAREs which represent their share in the pool (Vault).
  - Claim their rewards by burning their SHAREs after the period ends.

### Users Registry

Use cases:

- KYC team
  - Enable user accounts after KYC verification

### Vault

Syndicate shareholders can transfer their obligations to Web3 users by selling their ASSETs costs in exchange for the future profit. To do so, they use the Vault contract (Vault Contract), specifically an instance called the syndicate vault (vault).

The associated costs of ASSETs is a debt that the vault must repay through the sale of PART tokens.

The vault can function in three ways. There are three syndicate vaults existing for each period.

1. Fixed price with variable rate.

   ASSET has an associated cost. The ASSET’s owner can set the number of SHAREs to mint per one ASSET, thus specifying the price of 1 PART token.

   Different ASSETs can be sold for variable amount of SHAREs, allowing buyers to chose which ones to buy and thus regulate their participation level.

   Unsold SHAREs should be repaid by the ASSET owner. Unpaid debts are processed by the Syndicate Registry contract, according to the syndicate rules (e.g. sold).

2. The syndicate set a fixed price rate.

   The syndicate rules determine the number of SHAREs the ASSET can be divided into, which is managed and updated by the syndicate manager. In this case, all PART tokens of the syndicate cost the same price.

3. Floating rate.

   The pool's debt is represented by the ASSETs deposited into the vault's pool. Web3 users deposit their funds into the pool and receive SHAREs, which represent their share of the pool. In most cases, there will be a difference between the vault's debt and the collected funds.
   If the collected amount exceeds the debt, the difference is distributed among the ASSET owners whose tokens are in the pool. If the collected amount is less, the ASSET owners must repay the difference

   Unpaid debts are processed by the Syndicate Registry contract, according to the syndicate rules (e.g. sold).

Use cases:

- The ASSET owners
  - Deposit their ASSET(s) into one of the syndicate’s vault.
- Web3 users
  - Deposit funds into the vault and receive a shares of the pool.

### Payment system

#### General payments

- Asset owners
  - Withdraw payments paid by Web3 users.
  - Deposit to the Vault the reward at the end of each period.
- Shareholders
  - Claim their share of the reward.

#### Auction

It allows to liquidate unpaid ASSETs (by selling associated collateral and burning ASSETs).
