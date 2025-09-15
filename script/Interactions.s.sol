// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PayPerView} from "../src/PayPerView.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract PayPayPerView is Script {
    uint256 SEND_VALUE = 0.1 ether;

    function payPayPerView(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        PayPerView(payable(mostRecentlyDeployed)).payToView{value: SEND_VALUE}();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("PayPerView", block.chainid);
        payPayPerView(mostRecentlyDeployed);
    }
}

contract WithdrawPayPerView is Script {
    function withdrawPayPerView(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        PayPerView(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("PayPerView", block.chainid);
        withdrawPayPerView(mostRecentlyDeployed);
    }
}