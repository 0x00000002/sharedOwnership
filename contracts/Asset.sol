// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error AssetIsNotAvailable(uint256 assetId);

/**
 * @dev Asset token contract
 */
contract Asset is ERC721, AccessManaged {
    uint256 private _counter; // counter for minted tokens, starts from 1

    event Minted(address indexed receiver, uint256 tokenId);
    event Burned(uint256 tokenId);

    constructor(
        address manager
    ) ERC721("PART Asset", "pASSET") AccessManaged(manager) {}

    /**
     * @notice mint() function
     * @param receiver - address of the wallet to receive new token
     * @dev Restricted to the Asset Registry contract
     */

    function mint(
        address receiver
    ) public payable restricted returns (uint256) {
        _mint(receiver, ++_counter); // starts from 1
        emit Minted(receiver, _counter);
        return _counter;
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
