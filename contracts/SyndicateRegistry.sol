// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManaged.sol";

import "./HorseToken.sol";
import "./SYNDToken.sol";
import "./PaymentSystem.sol";

error ManagerExists();
error UnsupportedCurrency();

event RegistrationFeePaid(address indexed payer, bytes32 indexed syndicateId, uint256 amount);
event SharesBought(address indexed buyer, uint256 indexed syndicateId, uint256 amount);


/**
 * @dev FutureverAn example of ERC721 contract
 */
contract SyndicateRegistry is AccessManaged {
    HorseToken private _ht;
    SYNDToken private _syndt;
    PaymentSystem private _payer;


    struct Syndicate {
        address managerAccount;
        bytes32 custodianLink; // string or link or whatever
        uint256 horseId; 
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
        uint256 sharePrice; // could be 0
        uint256 maxSupply;
        HorseStatus status;
    }

    struct Shareholder {
        bytes32 syndicateId;
        string name;
        string email;
        string phone;
        string website;
    }

    uint256 private _syndicateIdCount;

    mapping(address shareholderAccount => Shareholder[]) public shareholders;
    mapping(address managerAccount => Manager) public managers;
    mapping(uint256 syndicateId => Syndicate) public syndicates;

    mapping(uint256 syndicateId => address[]) public syndicateShareholders;
    mapping(address addr => mapping(uint256 syndicateId => bool))
        public isShareholder;

    mapping(address shareholder => uint256) public sharesOwned;

    constructor(
        address horseToken,
        address syndToken,
        address paymentSystem,
        address manager
    ) AccessManaged(manager) {
        _ht = HorseToken(horseToken);
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
    ) external payable returns (uint256) {

        _payer.paySyndicateRegistrationFee{value: msg.value}();

        Syndicate memory syndicate = Syndicate(
            managerAccount,
            nztrSyndicateId,
            syndtId,
            conditions
        );

        syndicates[_syndicateIdCount] = syndicate;
        return _syndicateIdCount++;
    }

    function syndt() external view returns (address) {
        return address(_syndt);
    }

    function buyShares(
        uint256 syndicateId,
        uint256 amount,        
        PaymentSystem.Currency currency
    ) external payable {
        if (currency == PaymentSystem.Currency.XRP) {
            _payer.paySharesNativeCurrency{value: msg.value}(syndicateId, amount);
            emit SharesBought(msg.sender, syndicateId, amount);
        } else {
            revert UnsupportedCurrency();
        }
    }

    function sellShares(bytes32 syndicateId, uint256 purchaseId) external {
        // the one of the previous purchases will be sold
        // _payer.sellShares(syndicateId, purchaseId);
    }

}
