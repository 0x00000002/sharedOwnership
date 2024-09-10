# Participation token

## Problem statement

Numerous crowdfunding platforms exist, but they often share common issues.

- Centralization.
  - Platforms filter the projects they allow to participate.
  - Users are not able to recover their funds if lenders engage in fraud.
- Costs. There are few free crowdfunding platforms but they target non-profit organizations.

There is no suitable solution for small businesses or startups.

## Goals

Provide easy access to the global Web3 market and users' funds for anyone seeking to raise funds and acting trustworthy. The agreement must be reached in a decentralized, trustless manner.

## Proposed solution

Set of smart contracts, for transparency and trustworthiness, with Frontend for ease of use.

## Business requirements

**Dictionary:**

- ASSET: A digital token that represents the owner's assets.
- Lenders: Web3 users seeking to lend their funds in exchange for future profit.
- Payment System: It provides payment methods, token exchanges, and auctions.
- Collateral assets: Anything that can be sold at auction, e.g. cryptocurrency or NFTs.
- Vault: A smart contract that holds ASSETs and their collateral for a specified lending period.
- Expected reward: Set by the ASSET owner to be be paid at the end of the lending period.
- SHARE token: Minted to lenders. It relates to the ASSET, ASSET's collateral, and the expected reward for the specific lending period.

### Use case

Asset owners specify the funds they seek to raise, the duration they want to borrow money, and the potential reward after the lending period ends.

To assure lenders they can recoup their funds, the asset owner must deposit collateral, typically in the form of crypto tokens or NFTs.

The owner locks their asset(s) and collateral into the Vault. Now, anyone can review the collateral, the asset owner's history, and the expected reward, then decide whether to participate.

If the decision is positive, the borrower deposits their tokens or the native blockchain's currency (e.g., XRP for the Root Network or ETH for Ethereum) into the Vault and receives shares of that pool.

When the period ends, the asset owner deposits the reward (it might exceed the promised, but cannot be less than promised) into the Vault, and the assets (and their collateral) are unlocked. After that, lenders can claim their reward by burning their shares.

The reward cannot be guaranteed. However, the collateral provides some assurance, and the asset owner history can also be reviewed.

If the deposited reward is less than promised, the collateral may be sold to cover the difference.

If no reward is deposited at all, the collateral will be liquidated.

After the assets are unlocked, their collateral can be used for another asset or period.

### Supported currencies

Payments in various tokens should be supported, e.g. XRP (native currency of the Root Network), SYLO, ASTO, ROOT. This may necessitate the integration with decentralized exchanges, like Uniswap.

### Legal requirements

All users must be KYC verified. Asset/share tokens cannot be transferred to the non-KYC-verified account.

## Technical requirements

### Token extendibility

To provide the completeness of information regarding the asset, the ASSET token must be "extendable" in terms of data it contains. We can use a Dynamic Metadata registry (external project, out of scope of this one) for asset tokens to ensure:

- a fast start for this project, and
- the ability to introduce changes in the future.

### Metadata

We want to store assets metadata (where applicable, e.g. asset tokens) on IPFS and use CIDv1 to make it future proof.

### Upgradeability

All smart contracts should have dedicated storage to ensure future logic upgrades. Additionally, storage can also have a composite structure. Designing the logic to manage syndicates in advance can be challenging. The approach should either be as abstract as possible or made upgradeable.

## Architecture

Birds’ eye view, we will have 3 layers of smart contracts\*:

- Tokens
  - ASSET: a token representing ownership of the asset
  - SHARE: a token of participation in costs in exchange for a reward
- Business logic
  - Users Registry - to manage users and mint ASSETs
  - Vault contract - to manage agreements between asset owners and lenders
  - Collateral registry contract - to deposit (lock) collateral assets
- Payment system
  - Payments: deposits/withdrawals
  - Auction system - to sell collateral assets for unpaid shares
  - Swapper - an interface to (external) decentralized exchanges, e.g. Uniswap, to swap payment and collateral tokens

---

\* - Each contract, in turn, can have its own storage, and thus consist of two or more SHAREs.

![part_token](/docs/part_token.png)

## Business logic

### Users Registry

A smart contract that allows to manage users and mint new ASSETs.

**Use cases:**

- KYC team
  - Enable user accounts after KYC verification
- Asset owners
  - mint new ASSETs

### Asset token (ASSET)

A token representing the ownership of the asset.

The ASSETs deposited to the Vault represent the borrowing amount for a specific period, and the reward for the specified period.

**Use cases:**

- Asset owners
  lock any amount of their ASSETs and specify the duration of lock, and expected reward. Tokens are automatically unlocked when the period ends AND reward is deposited into the Vault contract, to be claimed by lenders.

### Collateral assets

Tokens that deposited into the Vault as collateral for the ASSETs can be sold at auction if no reward was deposited.

**Use cases:**

- Asset owners
  - Deposit collateral (XRP, ETH, ERC20, or ERC721/1155).
  - Withdraw collateral when the lending period ended and the reward deposited.
- Lenders
  - initiate collateral liquidation

### Asset's shares (SHARE token)

A token that represents a share of the lending pool during the specific period with associated expected reward.

Any Web3 users (lenders) can deposit their funds and receive SHARE tokens representing their share of the lending pool.

_N.B.: The share can't be "cancelled" or withdrawn before the end of the period, but can be traded or transferred to another user._

**Use cases:**

- Lenders
  - Deposit their funds into the pool and receive SHAREs of the pool.
  - Claim the reward from the Vault, by burning their SHAREs after the period ends and the reward is deposited.
  - Trade their shares (ERC1155) at any marketplace or transfer them to any wallet.

### Vault

The vault can operate in three ways. The asset owner can choose one of themwhen starting a new lending period.

1. Contribution based reward

   The ASSET’s owner sets the number of SHAREs to mint, and the reward per each SHARE token.

2. Pool-Proportioned Reward

   The asset owner specifies the reward they are willing to pay, independent of the funds raised. The pool accepts deposits before the period starts. Once the period begins, no further deposits are accepted. The expected reward is calculated when all deposits have been made.

3. Pool and time-proportioned reward

   Users can deposit funds into the pool at any time before the period ends. However, their reward will be proportional to both the amount deposited and the remaining time.

**Use cases:**

- The ASSET owners
  - Deposit their ASSET(s) into one of the pool.
- Web3 users
  - Deposit funds into the pool and receive a shares of the pool.

### Payment processor

**Use cases:**

- Asset owners
  - Withdraw lent funds.
  - Deposit the reward into the Vault at the end of the lending period.
- Lenders
  - Claim reward after lending period ends.

#### Auction

It allows to pay unpaid SHAREs by selling ASSET associated collateral.

- Anyone
  - can call `liquidate(collateralId)` function if the SHARE's reward was not deposited after the lending period ended.
