// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../contracts/CollateralManager.sol";
import "../contracts/Liquidator.sol";
import "../contracts/Vault.sol";
import "../contracts/VaultStorage.sol";
import "../contracts/Asset.sol";
import "../contracts/Share.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");

uint64 constant DEFAULT_ADMIN_ROLE = 0x00;
uint64 constant collateral_ADMIN = 0x01;
uint64 constant USERS_REGISTRY_ADMIN = 0x02;

/**
 * @dev Tests for the Collateral contract
 */
contract CollateralTests is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    AccessManager am_;
    Asset asset;
    VaultStorage storage_;
    CollateralManager collateral_;
    Vault vault_;
    Liquidator liquidator_;

    address aManager;
    address aAsset;
    address aShare;
    address aStorage;
    address aVault;
    address aLiquidator;

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
        setupCollateralManager();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        owner = makeAddr("owner");
        lender = makeAddr("lender");

        aAsset = makeAddr("ASSET");

        vm.label(admin, "ADMIN");
        vm.label(owner, "ASSET OWNER");
        vm.label(lender, "LENDER");
        vm.label(aAsset, "ASSET");
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
        assertTrue(canCall, "Admin can setup AM");
    }

    function setupCollateralManager() internal {
        asset = new Asset(aManager);
        aAsset = address(asset);
        storage_ = new VaultStorage(aManager);
        aStorage = address(storage_);
        vault_ = new Vault(aStorage, aAsset, aShare, aManager);
        aVault = address(vault_);
        liquidator_ = new Liquidator(aManager, aVault);
        aLiquidator = address(liquidator_);
        collateral_ = new CollateralManager(
            aAsset,
            aStorage,
            aLiquidator,
            2 * 10e6,
            4 * 10e6,
            6 * 10e6,
            8 * 10e6,
            10 * 10e6,
            aManager
        );
        aVault = address(collateral_);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = collateral_.setLiquidationFee.selector;

        vm.startPrank(admin);
        am_.grantRole(collateral_ADMIN, admin, 0);
        am_.setTargetFunctionRole(aVault, selectors, collateral_ADMIN);

        (bool canCall, ) = am_.canCall(
            admin,
            aVault,
            collateral_.setLiquidationFee.selector
        );
        assertTrue(canCall, "Admin is able to set fees");
        vm.stopPrank();
    }

    function test_setLiquidationFee_non_authorised_access() public {
        vm.prank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                owner
            )
        );
        collateral_.setLiquidationFee(CollateralManager.CollateralType.XRP, 3);
    }

    function test_setLiquidationFee_happy_path() public {
        vm.skip(false);

        vm.prank(admin);
        CollateralManager.CollateralType xrpType = CollateralManager
            .CollateralType
            .XRP;
        collateral_.setLiquidationFee(xrpType, 3);
        uint256 fee = collateral_.liquidationFees(xrpType);
        assertEq(fee, 3);
    }

    function test_requireLiquidationFee() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_depositXRP() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_depositErc20() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_depositNft() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_depositSft() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_depositOther() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_happy_xrp() public {
        vm.skip(true);

        // checks:
        // - asset is not free
        // - belongs to someone else
        // - erc20
        // - erc721
        // - erc1155
        // - xrp
        // - other ??

        assertEq(true, false);
    }

    function test_withdraw_lockedAsset() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_wrong_owner() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_happy_erc20() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_happy_erc721() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_happy_erc1155() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_happy_other() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_withdraw_liquidationd_fee_refunded() public {
        vm.skip(true);
        assertEq(true, false);
    }

    function test_liquidateCollateral() public {
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
