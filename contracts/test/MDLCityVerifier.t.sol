// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MDLCityVerifier} from "../src/MDLCityVerifier.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1VerifierGateway} from "@sp1-contracts/SP1VerifierGateway.sol";
import {SP1Verifier} from "@sp1-contracts/v2.0.0/SP1VerifierPlonk.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


/// A fixture that can be used to test the verification of SP1 zkVM proofs inside Solidity.
struct SP1ProofFixtureJson {
    bytes proof;
    bytes public_values;
    bytes32 vkey;
}

uint256 constant fixture1timestamp = 1728341932;
uint256 constant fixture2timestamp = 1728342166;
uint256 constant fixture3timestamp = 1728426219;


contract MDLCityVerifierTest is Test {
    using stdJson for string;

    address verifier;
    MDLCityVerifier public credIssuer;

    function loadFixture(string memory fixture) public view returns (SP1ProofFixtureJson memory) {

        string memory root = vm.projectRoot();
        string memory fixtureName = string.concat(fixture, ".json");
        string memory relativePath = string.concat("/test/example_fixtures/", fixtureName);
        string memory path = string.concat(root, relativePath);
        string memory json = vm.readFile(path);
        bytes memory jsonBytes = json.parseRaw(".");
        return abi.decode(jsonBytes, (SP1ProofFixtureJson));
    }


    function setUp() public {
        SP1ProofFixtureJson memory fixture = loadFixture("fixture1");

        verifier = address(new SP1Verifier());
        credIssuer = new MDLCityVerifier(verifier, fixture.vkey);
    }

    function test_ArbitraryCred() public {
        SP1ProofFixtureJson memory fixture = loadFixture("arbitrary");

        MDLCityVerifier.PublicValues memory v = abi.decode(fixture.public_values, (MDLCityVerifier.PublicValues));

        vm.warp(v.issuedAt + 1 minutes);

        try credIssuer.updateCred(fixture.public_values, fixture.proof) {
            console.log("Cred Valid.");
        } catch Error(string memory reason) {
            console.log("Cred Invalid");
            revert(reason);
        }


        assert(credIssuer.cred(v.id).owner == v.owner);
        assert(equal(credIssuer.cred(v.id).value, v.value));
        assert(credIssuer.cred(v.id).issuedAt == v.issuedAt);
    }


    function test_UpdateCred() public {
        SP1ProofFixtureJson memory fixture = loadFixture("fixture2");

        vm.warp(fixture2timestamp + 1 minutes);


        MDLCityVerifier.PublicValues memory v = abi.decode(fixture.public_values, (MDLCityVerifier.PublicValues));

        console.log("id:", v.id);
        console.log("iat:", v.issuedAt);
        console.log("value:", v.value);
        console.log("owner:", v.owner);

        vm.expectEmit(address(credIssuer));
        emit IERC721.Transfer(address(0), address(1), v.id);


        try credIssuer.updateCred(fixture.public_values, fixture.proof) {
            console.log("Updated");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }


        assert(credIssuer.cred(v.id).owner == address(1));
        assert(equal(credIssuer.cred(v.id).value, v.value));
        assert(credIssuer.cred(v.id).issuedAt == v.issuedAt);
    }


    function testFail_UpdateCredExpired() public {
        SP1ProofFixtureJson memory fixture = loadFixture("fixture1");


        vm.warp(fixture1timestamp + 2 hours);

        try credIssuer.updateCred(fixture.public_values, fixture.proof) {
            console.log("Updated");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }


    function testFail_UpdateCredRateLimited() public {
        SP1ProofFixtureJson memory fixture = loadFixture("fixture1");


        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture.public_values, fixture.proof);

        vm.warp(fixture1timestamp + 2 minutes);

        try credIssuer.updateCred(fixture.public_values, fixture.proof) {
            console.log("Updated");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }


    function test_LockCred() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");



        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture2timestamp + 1 minutes);

        vm.prank(address(1));

        try credIssuer.lockCred(fixture2.public_values, fixture2.proof) {
            console.log("Locked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }

        MDLCityVerifier.PublicValues memory v = abi.decode(fixture1.public_values, (MDLCityVerifier.PublicValues));

        assert(credIssuer.cred(v.id).locked == true);
    }


    function testFail_LockCredBadSender() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");



        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture2timestamp + 1 minutes);

        vm.prank(address(0));

        try credIssuer.lockCred(fixture2.public_values, fixture2.proof) {
            console.log("Locked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }

    function testFail_LockCredExpired() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");



        vm.warp(fixture1timestamp + 1 minutes);


        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture1timestamp + 2 hours);

        vm.prank(address(1));

        try credIssuer.lockCred(fixture2.public_values, fixture2.proof) {
            console.log("Locked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }


    function testFail_LockCredDuplicate() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");



        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture1timestamp + 2 minutes);

        vm.prank(address(1));

        try credIssuer.lockCred(fixture1.public_values, fixture1.proof) {
            console.log("Locked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }

    function test_UnlockCred() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");



        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture2timestamp + 1 minutes);

        vm.prank(address(1));

        credIssuer.lockCred(fixture2.public_values, fixture2.proof);

        MDLCityVerifier.PublicValues memory v = abi.decode(fixture1.public_values, (MDLCityVerifier.PublicValues));

        vm.prank(address(1));

        try credIssuer.unlockCred(v.id) {
            console.log("Unlocked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }

        assert(credIssuer.cred(v.id).locked == false);
    }


    function testFail_UnlockCred() public {
        SP1ProofFixtureJson memory fixture1 = loadFixture("fixture1");
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");



        vm.warp(fixture1timestamp + 1 minutes);

        credIssuer.updateCred(fixture1.public_values, fixture1.proof);

        vm.warp(fixture2timestamp + 1 minutes);

        vm.prank(address(1));

        credIssuer.lockCred(fixture2.public_values, fixture2.proof);

        MDLCityVerifier.PublicValues memory v = abi.decode(fixture1.public_values, (MDLCityVerifier.PublicValues));

        vm.prank(address(0));

        try credIssuer.unlockCred(v.id) {
            console.log("Unlocked");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }
    }


    function test_MoveCred() public {
        SP1ProofFixtureJson memory fixture2 = loadFixture("fixture2");
        SP1ProofFixtureJson memory fixture3 = loadFixture("fixture3");


        vm.warp(fixture2timestamp + 1 minutes);


        MDLCityVerifier.PublicValues memory v = abi.decode(fixture3.public_values, (MDLCityVerifier.PublicValues));


        vm.expectEmit(address(credIssuer));
        emit IERC721.Transfer(address(0), address(1), v.id);

        try credIssuer.updateCred(fixture2.public_values, fixture2.proof) {
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }

        assert(credIssuer.cred(v.id).owner == address(1));
        assert(credIssuer.balanceOf(address(1)) == 1);
        assert(credIssuer.balanceOf(address(2)) == 0);

        vm.warp(fixture3timestamp + 1 minutes);

        try credIssuer.updateCred(fixture3.public_values, fixture3.proof) {
            console.log("Moved");
        } catch Error(string memory reason) {
            console.log(reason);
            revert(reason);
        }

        assert(credIssuer.cred(v.id).owner == address(2));
        assert(credIssuer.balanceOf(address(1)) == 0);
        assert(credIssuer.balanceOf(address(2)) == 1);
        assert(credIssuer.ownerOf(v.id) == address(2));
    }


    // Inherited function behavior checks.
    function test_Symbol() public view {
        console.log(credIssuer.symbol());
    }

    function testFail_Approve() public view {
        try credIssuer.approve(address(0), 100) {
        } catch {
            console.log("Reverted");
            revert();
        }
    }


    function testFail_GetApproved() public view {
        try credIssuer.getApproved(100) {
        } catch {
            console.log("Reverted");
            revert();
        }
    }


    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }

}
