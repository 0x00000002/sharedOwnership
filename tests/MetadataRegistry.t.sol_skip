// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/manager/AccessManager.sol";

import "../src/examples/NFT.sol";
import "../src/MetadataRegistry.sol";
import "../src/utils/AccessManagedRoles.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

bytes32 constant label = keccak256("label");
bytes32 constant metatata = keccak256("metadata");

uint64 constant DEFAULT_ADMIN_ROLE = 0x00;
uint64 constant STUDIO_ROLE = 1001;

uint256 constant NFT_ID_0 = 0;
uint256 constant NFT_ID_1 = 1;

/**
 * @dev Tests for the ASM The Next Legend - Character contract
 */
contract MRTest is Test {
    // Naming convention: contracts variables ends with _, e.g.: nft_ or am_,
    // and their addresses starts with `a`, e.g.: aNft or aManager

    NFT nft_;
    MetadataRegistry mr_;
    AccessManager am_;
    SignersRegister sr_;

    address user;
    address admin;
    address signer1;
    address signer2;
    address studio1;
    address studio2;

    uint256 signer1PK;
    uint256 signer2PK;

    address aManager;
    address aNft;
    address aMetadataRegistry;
    address aSignersRegistry;

    bool isTrue;

    bytes32 strengthAtrrId = bytes32(abi.encodePacked("STRENGTH"));
    bytes32 staminaAtrrId = bytes32(abi.encodePacked("STAMINA"));
    bytes32 dexterityAtrrId = bytes32(abi.encodePacked("DEXTERITY"));

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
        setupTestContracts();
    }

    function setupAddresses() public {
        admin = vm.addr(
            vm.parseUint(
                "0xe49dcc90004a6788dcf67b74878c755d61502d686f76f1714f3ed91629fd4d52"
            )
        );

        user = makeAddr("user");
        studio1 = makeAddr("studio1");
        studio2 = makeAddr("studio2");

        vm.label(admin, "ADMIN");
        vm.label(user, "USER");
        vm.label(studio1, "STUDIO1");
        vm.label(studio2, "STUDIO2");

        (signer1, signer1PK) = makeAddrAndKey("signer1");
        (signer2, signer2PK) = makeAddrAndKey("signer2");
    }

    // AcessManager contract is deployed on both Porcini and ROOT chains,
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

        bytes4[] memory srSelectors = new bytes4[](1);
        srSelectors[0] = sr_.setSigner.selector;

        vm.startPrank(admin);
        am_.grantRole(STUDIO_ROLE, studio1, 0);
        am_.grantRole(STUDIO_ROLE, studio2, 0);
        am_.setTargetFunctionRole(aSignersRegistry, srSelectors, STUDIO_ROLE);

        (bool canCall, ) = am_.canCall(
            studio1,
            aSignersRegistry,
            srSelectors[0]
        );
        assertTrue(canCall, "Studio is able to set its signer");
        vm.stopPrank();

        vm.prank(studio1);
        sr_.setSigner(signer1, true);
        assertEq(sr_.getSigner(studio1), signer1);
        assertTrue(sr_.isSigner(signer1), "Signer1 is active");
        vm.stopPrank();

        vm.prank(studio2);
        sr_.setSigner(signer2, true);
        assertEq(sr_.getSigner(studio2), signer2);
        assertTrue(sr_.isSigner(signer2), "Signer2 is active");
        vm.stopPrank();
    }

    function setupTestContracts() public {
        // Deploy the MetadataRegistry
        mr_ = new MetadataRegistry(aManager, aSignersRegistry);
        aMetadataRegistry = address(mr_);

        bytes4[] memory mrSelectors = new bytes4[](2);
        mrSelectors[0] = mr_.addAttributes.selector;
        mrSelectors[1] = mr_.forceAttributes.selector;

        vm.startPrank(admin);
        am_.grantRole(STUDIO_ROLE, studio1, 0);
        am_.grantRole(STUDIO_ROLE, studio2, 0);
        am_.setTargetFunctionRole(aMetadataRegistry, mrSelectors, STUDIO_ROLE);
        vm.stopPrank();

        (isTrue, ) = am_.canCall(studio1, aMetadataRegistry, mrSelectors[0]);
        assertTrue(isTrue, "Studio is able to set attributes");
        (isTrue, ) = am_.canCall(studio1, aMetadataRegistry, mrSelectors[1]);
        assertTrue(isTrue, "Studio is able to set its signer");

        // console.log("MetadataRegistry address: %s", aMetadataRegistry);

        nft_ = new NFT("NFT", "NFT", aManager, aMetadataRegistry);
        aNft = address(nft_);

        // Prepopulate attributes

        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](2);

        attrs[0] = AttributesRegister.Attribute(strengthAtrrId, signer1);
        attrs[1] = AttributesRegister.Attribute(staminaAtrrId, signer1);

        vm.prank(studio1);
        mr_.addAttributes(aNft, attrs);
    }

    function test_addLabel_happy_path() public {
        vm.prank(admin);
        mr_.addLabel(aNft, label);
    }

    function test_addLabel_error_label_exists() public {
        vm.prank(admin);
        mr_.addLabel(aNft, label);
    }

    function test_addURI_happy_path() public {
        vm.prank(admin);
        mr_.addURI(aNft, 1, label, metatata);

        string memory uri = mr_.tokenURI(aNft, 1, label);

        assertEq(
            uri,
            "ipfs://bafybeid2tu5agk4p6j2pbfyuwvv2rzpno5xmsy4mumbqng6dumthxmrpmu"
        );
    }

    function test_addURI_error_uri_exist() public {
        vm.startPrank(admin);
        mr_.addURI(aNft, 1, label, metatata);
        bytes32 mrTokenId = keccak256(abi.encodePacked(aNft, NFT_ID_1));
        vm.expectRevert(
            abi.encodeWithSelector(UriExists.selector, mrTokenId, label)
        );

        mr_.addURI(aNft, 1, label, metatata);
    }

    function test_addURI_wrong_caller() public {
        vm.prank(user);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessManaged.AccessManagedUnauthorized.selector,
                user
            )
        );
        mr_.addURI(aNft, 1, label, metatata);
    }

    function test_setAttributes_happy_path() public {
        vm.skip(false);

        bytes32[] memory attrIds = new bytes32[](1);
        attrIds[0] = keccak256(abi.encodePacked(aNft, staminaAtrrId));
        uint256[] memory values = new uint256[](1);
        values[0] = 7;
        uint256 nonce = 123;

        bytes memory payload = abi.encode(
            aNft,
            NFT_ID_0,
            nonce,
            attrIds,
            values
        );

        bytes memory signature = _sign(payload, signer1PK);

        vm.prank(studio1);
        mr_.setAttributes(payload, signature);
    }

    function test_setAttributes_invalid_nonce() public {
        vm.skip(false);

        bytes32[] memory attrIds = new bytes32[](1);
        attrIds[0] = keccak256(abi.encodePacked(aNft, staminaAtrrId));
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        uint256 nonce = 0;

        bytes memory payload = abi.encode(
            aNft,
            NFT_ID_0,
            nonce,
            attrIds,
            values
        );

        bytes memory signature = _sign(payload, signer2PK);

        vm.prank(studio2);
        vm.expectRevert(abi.encodeWithSelector(InvalidNonce.selector, nonce));
        mr_.setAttributes(payload, signature);
    }

    function test_setAttributes_wrong_owner() public {
        vm.skip(false);

        bytes32[] memory attrIds = new bytes32[](1);
        attrIds[0] = keccak256(abi.encodePacked(aNft, staminaAtrrId));
        uint256[] memory values = new uint256[](1);
        values[0] = 50;
        uint256 nonce = 1;

        bytes memory payload = abi.encode(
            aNft,
            NFT_ID_0,
            nonce,
            attrIds,
            values
        );

        bytes memory signature = _sign(payload, signer2PK);

        vm.prank(studio2);
        vm.expectRevert(
            abi.encodeWithSelector(
                AttributesRegister.InvalidAttribute.selector,
                WRONG_ATTRIBUTE_OWNER,
                attrIds[0]
            )
        );
        mr_.setAttributes(payload, signature);
    }

    function test_setAttributes_error_AttributeExists() public {}

    function test_forceAttributes_happy_path() public {
        vm.skip(false);

        bytes32[] memory attrIds = new bytes32[](1);
        attrIds[0] = keccak256(abi.encodePacked(aNft, staminaAtrrId));
        uint256[] memory values = new uint256[](1);
        values[0] = 30;

        vm.startPrank(studio1);
        mr_.forceAttributes(aNft, NFT_ID_0, attrIds, values);
        vm.stopPrank();
    }

    function test_forceAttributes_wrong_owner() public {
        vm.skip(false);

        bytes32[] memory attrIds = new bytes32[](1);
        attrIds[0] = keccak256(abi.encodePacked(aNft, staminaAtrrId));
        uint256[] memory values = new uint256[](1);
        values[0] = 30;

        vm.prank(studio2);
        vm.expectRevert(
            abi.encodeWithSelector(
                AttributesRegister.InvalidAttribute.selector,
                WRONG_ATTRIBUTE_OWNER,
                attrIds[0]
            )
        );
        mr_.forceAttributes(aNft, NFT_ID_0, attrIds, values);
    }

    function test_addAttributes_attribute_exist() public {
        vm.skip(false);
        AttributesRegister.Attribute[]
            memory attrs = new AttributesRegister.Attribute[](1);

        attrs[0] = AttributesRegister.Attribute("STAMINA", signer1);

        bytes32 attrId = keccak256(abi.encodePacked(aNft, attrs[0].name));

        vm.startPrank(studio1);

        vm.expectRevert(
            abi.encodeWithSelector(
                AttributesRegister.InvalidAttribute.selector,
                ATTRIBUTE_EXISTS,
                attrId
            )
        );

        mr_.addAttributes(aNft, attrs);

        vm.stopPrank();
    }

    function _sign(
        bytes memory payload,
        uint256 signerPK
    ) internal pure returns (bytes memory) {
        bytes32 digest = _getEthSignedMessageHash(keccak256(payload));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);

        return abi.encodePacked(r, s, v);
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
}
