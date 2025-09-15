// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {PayPerView} from "../src/PayPerView.sol";

contract DeployPayPerView is Script {
    function deployPayPerView() public returns (PayPerView, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;

        vm.startBroadcast();
        string memory contentHash = "QmSomeIPFSHash";
        PayPerView payPerView = new PayPerView(priceFeed, contentHash);
        vm.stopBroadcast();
        return (payPerView, helperConfig);
    }

    function run() external returns (PayPerView, HelperConfig) {
        return deployPayPerView();
    }
}