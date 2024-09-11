// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../contracts/Collateral.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");

uint64 constant DEFAULT_ADMIN_ROLE = 0x00;
uint64 constant VAULT_ADMIN = 0x01;
uint64 constant USERS_REGISTRY_ADMIN = 0x02;

/**
 * @dev Tests for the Collateral contract
 */
contract CollateralTests is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    AccessManager am_;
    CollateralVault vault_;

    address aManager;
    address aVault;

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
        setupCollateralVault();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        owner = makeAddr("owner");
        lender = makeAddr("lender");

        vm.label(admin, "ADMIN");
        vm.label(owner, "ASSET OWNER");
        vm.label(lender, "LENDER");
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

    function setupCollateralVault() internal {
        vault_ = new CollateralVault(
            aManager,
            2 * 10e6,
            4 * 10e6,
            6 * 10e6,
            8 * 10e6,
            10 * 10e6
        );
        aVault = address(vault_);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = vault_.setLiquidationFee.selector;

        vm.startPrank(admin);
        am_.grantRole(VAULT_ADMIN, admin, 0);
        am_.setTargetFunctionRole(aVault, selectors, VAULT_ADMIN);

        (bool canCall, ) = am_.canCall(
            admin,
            aVault,
            vault_.setLiquidationFee.selector
        );
        assertTrue(canCall, "Admin is able to set fees");
        vm.stopPrank();
    }

    function test_setLiquidationFee_restricted() public {
        vm.prank(owner);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                owner
            )
        );
        vault_.setLiquidationFee(CollateralVault.CollateralType.XRP, 3);
    }

    function test_setLiquidationFee_happy_path() public {
        vm.skip(false);

        vm.prank(admin);
        CollateralVault.CollateralType xrpType = CollateralVault
            .CollateralType
            .XRP;
        vault_.setLiquidationFee(xrpType, 3);
        uint256 fee = vault_.liquidationFees(xrpType);
        assertEq(fee, 3);
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

    function test_withdrawDeposited() public {
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
