// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "./HorseToken.sol";

string constant BASE_URI = "https://token-cdn-domain/{id}.json";

/**
 * @dev Syndicate Token contract
 */
contract SYNDToken is ERC1155, AccessManaged {
    event Minted(address indexed receiver, uint256 tokenId);
    event Burned(uint256 tokenId);

    mapping(address manager => bool) private _managers;

    constructor(address manager) ERC1155(BASE_URI) AccessManaged(manager) {}

    /**
     * @notice mint() function
     * @param receiver - address of the wallet to receive new token
     * @param horse - Horse struct
     */

    function mint(
        address receiver,
        uint256 amount,
        HorseToken.Horse calldata horse
    ) public payable onlyManager returns (uint256 tokenId) {
        tokenId = uint256(
            keccak256(
                abi.encodePacked(
                    horse.name,
                    horse.horseType,
                    horse.color,
                    horse.dob,
                    horse.isStallion,
                    horse.sire,
                    horse.dam
                )
            )
        );
        _mint(receiver, tokenId, amount, "");
        emit Minted(receiver, tokenId);
    }

    /**
     * @notice Optional burn() function - EXAMPLE for testing purpose
     * @param tokenId The token ID to burn
     */
    function burn(
        address from,
        uint256 tokenId,
        uint256 value
    ) external onlyManager {
        _burn(from, tokenId, value);
        emit Burned(tokenId);
    }

    modifier onlyManager() {
        require(_managers[msg.sender], "Restricted to managers");
        _;
    }
}
