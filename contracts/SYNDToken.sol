// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

string constant NAME = "Syndicate Token";
string constant TOKEN = "SYNDT";

enum HorseType {
    Thoroughbred,
    Standardbred,
    QuarterHorse,
    Arabian,
    Appaloosa,
    Paint,
    Mustang,
    Other
}

enum Color {
    Bay,
    Black,
    Brown,
    Chestnut,
    Gray,
    Roan,
    White,
    Other
}

enum HorseStatus {
    Active,
    Retired,
    Deceased,
    Sold,
    Stolen,
    Lost,
    Other
}

/**
 * @dev Syndicate Token contract
 */
contract SYNDToken is ERC721, AccessManaged {
    struct Horse {
        bytes32 name; // maximum 32 characters in the name
        HorseType horseType;
        HorseStatus status;
        Color color;
        uint256 dob; // date of birth, unix timestamp with hours/minutes/seconds ignored
        bool isStallion;
        bytes32 sire;
        bytes32 dam;
    }

    mapping(bytes32 tokenId => Horse) public horses;

    event Minted(address indexed receiver, uint256 tokenId);
    event Burned(uint256 tokenId);

    constructor(address manager) ERC721(NAME, TOKEN) AccessManaged(manager) {}

    /**
     * @notice mint() function
     * @param receiver - address of the wallet to receive new token
     * @param horse - Horse struct
     */

    function mint(
        address receiver,
        Horse calldata horse
    ) public payable restricted {
        bytes32 tokenId = keccak256(
            abi.encodePacked(
                horse.name,
                horse.horseType,
                horse.color,
                horse.dob,
                horse.isStallion,
                horse.sire,
                horse.dam
            )
        );
        _mint(receiver, uint256(tokenId));
        emit Minted(receiver, uint256(tokenId));
    }

    /**
     * @notice Optional burn() function - EXAMPLE for testing purpose
     * @param tokenId The token ID to burn
     */
    function burn(uint256 tokenId) external restricted {
        _burn(tokenId);
        emit Burned(tokenId);
    }
}
