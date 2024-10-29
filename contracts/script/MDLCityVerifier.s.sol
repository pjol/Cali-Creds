// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MDLCityVerifier} from "../src/MDLCityVerifier.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1VerifierGateway} from "@sp1-contracts/SP1VerifierGateway.sol";

struct SP1ProofFixtureJson {
    bytes proof;
    bytes public_values;
    bytes32 vkey;
}

address constant sepolia_validator = 0xaeE21CeadF7A03b3034DAE4f190bFE5F861b6ebf;
address constant amoy_validator = 0xAf1bE36339424FAFb83eE63B0A4200F1877E5526;


contract MDLCityVerifierScript is Script {
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
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        SP1ProofFixtureJson memory fixture = loadFixture("arbitrary");
        verifier = address(amoy_validator);
        console.log("starting broadcast");
        vm.startBroadcast(deployerPrivateKey);
        credIssuer = new MDLCityVerifier(verifier, fixture.vkey);
        vm.stopBroadcast();
    }
}
