// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../src/examples/NFT.sol";
import "../src/MetadataRegistry.sol";
import "../src/AttributesRegister.sol";
import "../src/utils/AccessManagedRoles.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");
bytes32 constant metatata = keccak256("metadata");

uint64 constant DEFAULT_ADMIN_ROLE = 0x00;
uint64 constant STUDIO_ROLE = 1001;

/**
 * @dev Tests for the ASM The Next Legend - Character contract
 */
contract MRTest is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    AccessManager am_;
    SignersRegister sr_;

    address aSignersRegistry;
    address aManager;

    address user;
    address admin;
    address studio;
    address signer;
    uint256 signerPK;

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
        setupSignersRegister();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );
        user = makeAddr("user");
        studio = makeAddr("studio");
        (signer, signerPK) = makeAddrAndKey("signer");

        vm.label(admin, "ADMIN");
        vm.label(user, "USER");
        vm.label(studio, "STUDIO");
        vm.label(signer, "SIGNER");
    }

    // AcessManager contract must be pre-deployed on both Porcini and ROOT chains,
    // this setup recreates the roles of the real AccessManager contract
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
        assertTrue(canCall, "FV Admin can setup AM");
    }

    function setupSignersRegister() internal {
        sr_ = new SignersRegister(aManager);
        aSignersRegistry = address(sr_);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = sr_.setSigner.selector;

        vm.startPrank(admin);
        am_.grantRole(STUDIO_ROLE, studio, 0);
        am_.setTargetFunctionRole(aSignersRegistry, selectors, STUDIO_ROLE);

        (bool canCall, ) = am_.canCall(
            studio,
            aSignersRegistry,
            sr_.setSigner.selector
        );
        assertTrue(canCall, "Studio is able to set its signer");
        vm.stopPrank();

        vm.prank(studio);
        sr_.setSigner(signer, true);
        assertEq(sr_.getSigner(studio), signer);
        assertTrue(sr_.isSigner(signer), "Signer is active");
    }

    function test_setSigner_restricted() public {
        vm.prank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                user
            )
        );
        sr_.setSigner(signer, true);
    }

    function test_setSigner_happy_path() public {
        vm.skip(false);

        vm.prank(studio);
        sr_.setSigner(signer, true);
        address res = sr_.getSigner(studio);
        assertEq(res, signer);
    }

    function test_validateSignature_error() public {
        bytes memory data = abi.encodePacked("data");
        bytes memory wrongData = abi.encodePacked("another data");

        bytes memory wrongSignature = _sign(wrongData);

        vm.expectRevert(
            abi.encodeWithSelector(InvalidSigner.selector, UNKNOWN_SIGNER)
        );

        sr_.validateSignature(data, wrongSignature);
    }

    function test_validateSignature_happy_path() public view {
        bytes memory data = abi.encodePacked("data");
        bytes memory signature = _sign(data);
        bytes32 digest = _getEthSignedMessageHash(keccak256(data));
        address signer_ = _recoverSigner(digest, signature);
        assertEq(signer_, signer);

        sr_.validateSignature(data, signature);
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

    function _sign(bytes memory payload) internal view returns (bytes memory) {
        bytes32 digest = _getEthSignedMessageHash(keccak256(payload));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);

        return abi.encodePacked(r, s, v);
    }

    function _recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) private pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    function _getEthSignedMessageHash(
        bytes32 messageHash
    ) private pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function _splitSignature(
        bytes memory sig
    ) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (v, r, s)
    }

    function _verify(
        address contractAddress,
        uint256 tokenId,
        uint256 nonce,
        bytes32[] memory ids,
        uint256[] memory values,
        bytes memory signature,
        address _signer
    ) private returns (bool) {
        emit BytesEvent(signature);
        bytes32 messageHash = keccak256(
            abi.encode(contractAddress, tokenId, nonce, ids, values)
        );
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);
        address signer_ = _recoverSigner(ethSignedMessageHash, signature);
        console.log("signer:", signer_);
        return signer_ == _signer;
    }
}
