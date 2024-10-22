// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../contracts/Vault.sol";
import "../contracts/VaultStorage.sol";
import "../contracts/Asset.sol";
import "../contracts/Share.sol";
import "../contracts/UsersRegistry.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");

uint64 constant DEFAULT_ADMIN_ROLE = 0x00;
uint64 constant VAULT_ADMIN = 0x01;
uint64 constant USERS_REGISTRY_ADMIN = 0x02;

/**
 * @dev Tests for the Collateral contract
 */
contract VaultTests is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    AccessManager am_;
    VaultStorage storage_;
    Vault vault_;

    address aStorage;
    address aManager;
    address aAsset;
    address aShare;
    address aVault;
    address aUserRegistry;

    address owner;
    address admin;
    address lender;

    event BytesEvent(bytes hash);
    event Bytes32Event(bytes32 hash);

    /** ----------------------------------
     * ! Setup
     * ----------------------------------- */

    // The state of the contract gets reset before each
    // test is run, with the `setUp()` function being called
    // each time after deployment. Think of this like a JavaScript
    // `beforeEach` block
    function setUp() public {
        setupAddresses();
        setupAccessManager();
        setupVaultContract();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        owner = makeAddr("owner");
        lender = makeAddr("lender");

        aUserRegistry = makeAddr("UserRegistryContract");
        aAsset = makeAddr("AssetContract");
        aShare = makeAddr("ShareContract");

        vm.label(admin, "ADMIN");
        vm.label(owner, "ASSET OWNER");
        vm.label(lender, "LENDER");
        vm.label(aUserRegistry, "USER_REGISTRY_");
        vm.label(aAsset, "vault_");
        vm.label(aShare, "SHARE_");
    }

    // AcessManager contract must be pre-deployed
    function setupAccessManager() internal {
        am_ = new AccessManager(admin);
        aManager = address(am_);
        vm.label(aManager, "AccessManager");

        (bool hasRole, ) = am_.hasRole(DEFAULT_ADMIN_ROLE, admin);
        assertTrue(hasRole, "Admin has default role");

        (bool canCall, ) = am_.canCall(
            admin,
            aManager,
            am_.setTargetFunctionRole.selector
        );
        assertTrue(canCall, "Admin can mint");
    }

    function setupVaultContract() internal {
        storage_ = new VaultStorage(aManager);
        aStorage = address(storage_);
        vault_ = new Vault(aStorage, aAsset, aShare, aManager);
        aVault = address(vault_);

        // bytes4[] memory selectors = new bytes4[](1);

        // vm.startPrank(admin);
        // am_.grantRole(VAULT_ADMIN, admin, 0);
        // am_.setTargetFunctionRole(aAsset, selectors, VAULT_ADMIN);

        // (bool canCall, ) = am_.canCall(admin, aVault, vault_.addPair.selector);
        // assertTrue(canCall, "Admin is able to add new ASSET/SHAIR pair");
        // vm.stopPrank();
    }

    function test_addPair() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_newPeriod() public {
        vm.skip(true);
        assertEq(true, false);
    }

    /** ----------------------------------
     * ! Helpers for this contract
     * ----------------------------------- */

    function getRoleErrorMessage(
        address addr,
        bytes32 role
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(uint160(addr), 20),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            );
    }
}
