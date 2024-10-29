// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MDLCityVerifier} from "../src/MDLCityVerifier.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {SP1Verifier} from "@sp1-contracts/v2.0.0/SP1VerifierPlonk.sol";



contract DeployPlonkVerifierScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new SP1Verifier();
        vm.stopBroadcast();
    }
}
