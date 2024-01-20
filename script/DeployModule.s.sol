// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

// Import modules here
import { FlashcallFallbackExecutor } from "../src/executors/FlashcallFallbackExecutor.sol";

/// @title DeployModuleScript
contract DeployModuleScript is Script {
    function run() public {
        // Setup module bytecode, deploy params, and data

        // Get private key for deployment
        vm.startBroadcast(vm.envUint("PK"));

        // Deploy module
        // address module = deployModule({
        //     code: bytecode,
        //     deployParams: deployParams,
        //     salt: bytes32(0),
        //     data: data
        // });
        address token = 0xc4bF5CbDaBE595361438F8c6a187bDc330539c60;
        address flashloanLender = 0xB5d0ef1548D9C70d3E7a96cA67A2d7EbC5b1173E;
        address aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;

        FlashcallFallbackExecutor executor = new FlashcallFallbackExecutor(
            0x39569Bfb835B4577C55c1AAC4B3Fe9fBf3bcDd57, // _fallbackHandler
            0xc4bF5CbDaBE595361438F8c6a187bDc330539c60,
            flashloanLender,
            aavePool
        );

        // Stop broadcast and log module address
        vm.stopBroadcast();
    }
}
