// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {PayPerView} from "../../src/PayPerView.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract InteractionsTest is Test {
    PayPerView public payPerView;
    HelperConfig public helperConfig;
    address public user = address(0xBEEF);
    uint256 public constant SEND_VALUE = 0.1 ether;

    function setUp() public {
        helperConfig = new HelperConfig();
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;
        payPerView = new PayPerView(priceFeed, "Hello premium viewer!");
    }

    function testUserCanPayToView() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        uint256 amountPaid = payPerView.getAddressToAmountPaid(user);
        assertGt(amountPaid, 0);
    }

    function testUserCanViewAfterPayment() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        vm.prank(user);
        string memory content = payPerView.viewContentHash();
        assertEq(content, "Hello premium viewer!");
    }

    function testRevertIfUserTriesToViewWithoutPaying() public {
        vm.expectRevert("Access denied: Pay first");
        vm.prank(user);
        payPerView.viewContentHash();
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(user);
        payPerView.withdraw();
    }
}
