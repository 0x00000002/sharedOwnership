// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

/**
 * @dev Asset token contract
 */
contract CollateralVault is AccessManaged {
    enum CollateralType {
        XRP,
        ERC20,
        ERC721,
        ERC1155,
        Other
    }

    struct Collateral {
        CollateralType collateralType;
        uint16 timestamp;
        address contractAddress;
        uint256 assetId;
        uint256 amount;
    }

    uint256 public liquidationFee;

    mapping(uint256 assetId => Collateral[]) collaterals;
    mapping(CollateralType => uint256 fee) public liquidationFees;

    event ERC20Deposited(
        uint256 indexed assetId,
        address indexed contractAddress,
        uint256 amount,
        uint16 timestamp
    );
    event ERC721Deposited(
        uint256 indexed assetId,
        address indexed contractAddress,
        uint256 tokenId,
        uint16 timestamp
    );
    event ERC1155Deposited(
        uint256 indexed assetId,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint16 timestamp
    );
    event OtherDeposit(
        uint256 indexed assetId,
        uint16 timestamp,
        bytes32 jsonUri // URI of the json with description
    );

    error FailedToSend(CollateralType collateralType, uint256 value);
    error DepositNotExist(uint256 assetId, uint256 index);

    constructor(
        address manager,
        uint256 xrpLiquidationFee,
        uint256 erc721Liquidationfee,
        uint256 erc1155LiquidationFee,
        uint256 erc20LiquidationFee,
        uint256 otherLiquidationFee
    ) AccessManaged(manager) {
        liquidationFees[CollateralType.XRP] = xrpLiquidationFee;
        liquidationFees[CollateralType.ERC721] = erc721Liquidationfee;
        liquidationFees[CollateralType.ERC1155] = erc1155LiquidationFee;
        liquidationFees[CollateralType.ERC20] = erc20LiquidationFee;
        liquidationFees[CollateralType.Other] = otherLiquidationFee;
    }

    /**
     *
     * @param assetId - id of the asset
     */
    function depositXrp(
        uint256 assetId
    ) external payable requireLiquidationFee(CollateralType.XRP) {
        Collateral memory collateral = Collateral(
            CollateralType.XRP,
            uint16(block.timestamp),
            address(0),
            0,
            msg.value
        );
        collaterals[assetId].push(collateral);
    }

    function depositNft(
        uint256 assetId,
        address contractAddress,
        uint256 tokenId
    ) external payable requireLiquidationFee(CollateralType.ERC721) {
        collaterals[assetId].push(
            Collateral(
                CollateralType.ERC721,
                uint16(block.timestamp),
                contractAddress,
                tokenId,
                1
            )
        );
        emit ERC721Deposited(
            assetId,
            contractAddress,
            tokenId,
            uint16(block.timestamp)
        );
    }

    function depositSft(
        uint256 assetId,
        address contractAddress,
        uint256 tokenId,
        uint256 value
    ) external payable requireLiquidationFee(CollateralType.ERC1155) {
        collaterals[assetId].push(
            Collateral(
                CollateralType.ERC1155,
                uint16(block.timestamp),
                contractAddress,
                tokenId,
                value
            )
        );
        emit ERC1155Deposited(
            assetId,
            contractAddress,
            tokenId,
            value,
            uint16(block.timestamp)
        );
    }

    function depositErc20(
        address contractAddress,
        uint256 assetId,
        uint256 amount
    ) external payable requireLiquidationFee(CollateralType.ERC20) {
        collaterals[assetId].push(
            Collateral(
                CollateralType.ERC20,
                uint16(block.timestamp),
                contractAddress,
                0,
                amount
            )
        );
        emit ERC20Deposited(
            assetId,
            contractAddress,
            amount,
            uint16(block.timestamp)
        );
    }

    // TODO: think how to represent non-web3 assets
    function depositOther(
        uint256 assetId,
        bytes32 jsonUri
    ) external payable requireLiquidationFee(CollateralType.Other) {
        collaterals[assetId].push(
            Collateral(
                CollateralType.Other,
                uint16(block.timestamp),
                address(0),
                0,
                0
            )
        );
        emit OtherDeposit(assetId, uint16(block.timestamp), jsonUri);
    }

    function withdrawDeposit(
        uint256 assetId,
        uint256 index,
        address to
    ) external {
        Collateral[] storage _collaterals = collaterals[assetId];
        if (index >= _collaterals.length) {
            revert DepositNotExist(assetId, index);
        }
        Collateral memory collateral = _collaterals[index];
        uint256 value;
        CollateralType collateralType = collateral.collateralType;
        if (collateralType == CollateralType.XRP) {
            value = collateral.amount + liquidationFees[CollateralType.XRP];
        } else if (collateralType == CollateralType.ERC20) {
            ERC20(collateral.contractAddress).transferFrom(
                address(this),
                to,
                collateral.amount
            );
            value = liquidationFees[CollateralType.ERC20];
        } else if (collateralType == CollateralType.ERC721) {
            ERC721(collateral.contractAddress).transferFrom(
                address(this),
                to,
                collateral.assetId
            );
            value = liquidationFees[CollateralType.ERC721];
        } else if (collateralType == CollateralType.ERC1155) {
            ERC1155(collateral.contractAddress).safeTransferFrom(
                address(this),
                to,
                collateral.assetId,
                collateral.amount,
                ""
            );
            value = liquidationFees[CollateralType.ERC1155];
        }

        (bool sent, ) = payable(to).call{value: value}("LiquidationFee Refund");
        require(sent, FailedToSend(collateralType, value));

        // the "Other" type is not withdrawable at this stage.

        _collaterals[index] = _collaterals[_collaterals.length - 1];
        _collaterals.pop();
    }

    /**
     * @notice Liquidate the collateral
     * @notice The liquidation fee was collected on deposit.
     * @notice The ERC2771Forwarder is used to sponsor the liquidator,
     * @notice so anyone can call this function, without paying the gas.
     * @param assetId - id of the asset which collateral to liquidate
     */
    function liquidateCollateral(uint256 assetId) external {
        Collateral[] storage _collaterals = collaterals[assetId];
        for (uint256 i = 0; i < _collaterals.length; i++) {
            Collateral memory collateral = _collaterals[i];

            // send collaterals to the liquidator
        }
    }

    // !------------------------
    // ! Admin functions
    // !------------------------

    /**
     * @notice Set liquidation fee for the collateral
     * @param feeType - type of the collateral
     * @param amount - fee amount
     */

    function setLiquidationFee(
        CollateralType feeType,
        uint256 amount
    ) external restricted {
        liquidationFees[feeType] = amount;
    }

    modifier requireLiquidationFee(CollateralType collateralType) {
        require(
            msg.value >= liquidationFees[collateralType],
            "CollateralVault: insufficient liquidation fee"
        );
        _;
    }
}
