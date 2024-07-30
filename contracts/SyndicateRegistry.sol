// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import "./SYNDToken.sol";
import "./PaymentSystem.sol";

error ManagerExists();

/**
 * @dev FutureverAn example of ERC721 contract
 */
contract SyndicateRegistry is AccessManaged {
    SYNDToken private _syndt;
    PaymentSystem private _payer;

    struct Syndicate {
        address managerAccount;
        bytes32 nztrSyndicateId; // string? number?
        uint256 syndtId; // SYNDT's ID
        Conditions conditions;
    }

    struct Manager {
        string name; // legal name or business name
        string email;
        string phone;
        string website;
    }

    struct Conditions {
        uint256 totalShares;
        HorseStatus status;
    }

    struct Shareholder {
        bytes32 syndicateId;
        string name;
        string email;
        string phone;
        string website;
    }

    mapping(address shareholderAccount => Shareholder[]) public shareholders;
    mapping(address managerAccount => Manager) public managers;
    mapping(bytes32 syndicateId => Syndicate) public syndicates;

    mapping(bytes32 syndicateId => address[]) public syndicateShareholders;
    mapping(address addr => mapping(bytes32 syndicateId => bool))
        public isShareholder;

    constructor(
        address syndToken,
        address paymentSystem,
        address manager
    ) AccessManaged(manager) {
        _syndt = SYNDToken(syndToken);
        _payer = PaymentSystem(paymentSystem);
    }

    function updateManager(
        string memory name,
        string memory email,
        string memory phone,
        string memory website
    ) external restricted {
        managers[msg.sender] = Manager(name, email, phone, website);
    }

    function registerSyndicate(
        address managerAccount,
        bytes32 nztrSyndicateId,
        uint256 syndtId,
        Conditions calldata conditions
    ) external payable {
        bytes32 syndicateId = keccak256(
            abi.encodePacked(managerAccount, nztrSyndicateId, syndtId)
        );

        _payer.paySyndicateRegistrationFee{value: msg.value}(syndicateId);

        Syndicate memory syndicate = Syndicate(
            managerAccount,
            nztrSyndicateId,
            syndtId,
            conditions
        );

        syndicates[nztrSyndicateId] = syndicate;
    }

    function syndt() external view returns (address) {
        return address(_syndt);
    }
}
