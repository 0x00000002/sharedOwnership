// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error AssetIsNotAvailable(uint256 assetId);

/**
 * @dev Asset token contract
 */
contract Asset is ERC721, AccessManaged {
    uint256 private _counter;

    enum Status {
        Clear, // no assigned period or unpaid debts,
        InProgress, // period has assigned, work in progress
        Overdue, // standard waiting period is over, waiting for the payment
        Liquidation // no payment received, collateral is in liquidation (under auction)
    }

    mapping(uint256 assetId => Status) private _status;

    event Minted(address indexed receiver, uint256 tokenId);
    event Burned(uint256 tokenId);

    constructor(
        address manager
    ) ERC721("PART Asset", "pASSET") AccessManaged(manager) {}

    /**
     * @notice Transfer checks if the token is available
     * @notice to avoid tokens being traded while locked or liquidated
     * @param from - address of the wallet to transfer token from
     * @param to - address of the wallet to transfer token to
     * @param assetId - id of the asset
     */
    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) public override {
        require(_status[assetId] == Status.Clear, AssetIsNotAvailable(assetId));
        super.transferFrom(from, to, assetId);
    }

    /**
     * @notice safeTransferFrom() function
     * @notice safeTransferFrom checks if the token is not locked or liquidated
     * @param from - address of the wallet to transfer token from
     * @param to - address of the wallet to transfer token to
     * @param assetId - id of the asset
     * @param data - additional data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes memory data
    ) public override {
        require(_status[assetId] == Status.Clear, AssetIsNotAvailable(assetId));
        super.safeTransferFrom(from, to, assetId, data);
    }

    /**
     * @notice Returns asset details
     * @param assetId - id of asset
     * @return asset details (owner, status)
     */
    function assetStatus(uint256 assetId) external view returns (Status) {
        return _status[assetId];
    }

    function isFree(uint256 assetId) external view returns (bool) {
        return _status[assetId] == Status.Clear;
    }

    /**
     * @notice mint() function
     * @param receiver - address of the wallet to receive new token
     * @dev Restricted to the Asset Registry contract
     */

    function mint(
        address receiver
    ) public payable restricted returns (uint256) {
        _mint(receiver, _counter);
        emit Minted(receiver, _counter);
        return _counter++;
    }

    /**
     * @notice Optional burn() function - EXAMPLE for testing purpose
     * @param tokenId The token ID to burn
     * @dev Restricted to the Asset Registry contract
     */
    function burn(uint256 tokenId) external restricted {
        _burn(tokenId);
        emit Burned(tokenId);
    }
}
