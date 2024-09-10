// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./Asset.sol";
import "./payments/PaymentProcessor.sol";

error AccountAlreadyRegistered();
error UnknownAccount();

/**
 * @dev Contract for managing assets
 */
contract UsersRegistry is AccessManaged {
    enum KYC {
        New,
        Email,
        ID
    }

    Asset private _asset;
    PaymentProcessor private _processor;

    mapping(address account => KYC level) private _kyc;
    mapping(address account => uint256[]) private _userAssets;

    event AccountVerified(address indexed account, KYC indexed level);
    event AssetRegistered(address indexed user, uint256 assetId);

    constructor(
        address asset,
        address processor,
        address manager
    ) AccessManaged(manager) {
        _asset = Asset(asset);
        _processor = PaymentProcessor(processor);
    }

    // !----------------------
    // ! Getters
    // !----------------------

    /**
     * @notice Check account's verification
     * @param account address
     * @return verification level
     */
    function accountVerificationLevel(
        address account
    ) external view returns (KYC) {
        return _kyc[account];
    }

    // !----------------------
    // ! User functions
    // !----------------------

    /**
     * @notice Register new user account
     * @param account - address of the account
     * @param feeCurrency - currency in which the fee to be paid
     * @dev Restricted to the Asset Registry contract
     */
    function registerUser(
        address account,
        PaymentProcessor.Currency feeCurrency
    ) external payable {
        require(uint8(_kyc[account]) < 1, AccountAlreadyRegistered());
        _processor.payFee{value: msg.value}(
            feeCurrency,
            PaymentProcessor.Fee.OwnerRegistration
        );
        _kyc[account] = KYC.New;
    }

    /**
     * @notice Register (and mint) new Asset
     * @param currency to pay the fee
     * @return assetId - new asset's ID
     */
    function registerAsset(
        PaymentProcessor.Currency currency
    ) external payable returns (uint256 assetId) {
        _processor.payFee{value: msg.value}(
            currency,
            PaymentProcessor.Fee.AssetRegistration
        );
        address msgSender = msg.sender;
        assetId = _asset.mint(msgSender);
        _userAssets[msgSender].push(assetId);

        emit AssetRegistered(msgSender, assetId);
    }

    // !----------------------
    // ! Admin functions
    // !----------------------

    /**
     * @notice Verify user account, update KYC level
     * @param account - address of the account
     * @param level - KYC verification level
     * @dev Restricted to the KYC managers
     */
    function verifyAccount(address account, KYC level) external restricted {
        _kyc[account] = level;
        emit AccountVerified(account, level);
    }

    /**
     * @notice modifier checks if the account is registered in the system
     */
    modifier isVerified(address account) {
        if (uint8(_kyc[account]) > 0) _;
        else revert UnknownAccount();
    }
}
