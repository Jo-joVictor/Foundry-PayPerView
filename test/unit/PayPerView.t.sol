// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {PayPerView} from "../../src/PayPerView.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract PayPerViewTest is Test {
    PayPerView public payPerView;
    address public owner;
    address public user;
    MockV3Aggregator public mockPriceFeed;

    uint256 public constant SEND_VALUE = 0.1 ether;
    int256 public constant INITIAL_PRICE = 2000e8; // $2000 ETH
    uint8 public constant DECIMALS = 8;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        vm.deal(user, 10 ether);   // give user ETH
        vm.deal(owner, 0 ether);   // owner starts with 0

        mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);

        vm.prank(owner);
        payPerView = new PayPerView(address(mockPriceFeed), "Exclusive content!");
    }

    function testRevertIfNotEnoughETH() public {
        vm.prank(user);
        vm.expectRevert(bytes("You don't have Enough ETH!"));
        payPerView.payToView{value: 1e14}(); // way less than $5
    }

    function testRecordsPayment() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        uint256 amountPaid = payPerView.getAddressToAmountPaid(user);
        assertEq(amountPaid, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        address firstFunder = payPerView.getPayer(0);
        assertEq(firstFunder, user);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.prank(user);
        vm.expectRevert(bytes("You don't have Enough ETH!"));
        payPerView.payToView{value: 1 wei}();
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        vm.prank(user);
        vm.expectRevert(); // not owner
        payPerView.withdraw();
    }

    function testOwnerCanWithdraw() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        payPerView.withdraw();

        uint256 balanceAfter = owner.balance;
        assertGt(balanceAfter, balanceBefore);
    }

    function testCheaperWithdrawClearsState() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        vm.prank(owner);
        payPerView.cheaperWithdraw();

        uint256 userPaid = payPerView.getAddressToAmountPaid(user);
        assertEq(userPaid, 0);

        vm.expectRevert(); // because s_payers is reset
        payPerView.getPayer(0);
    }

    function testViewContentAfterPayment() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        vm.prank(user);
        string memory content = payPerView.viewContentHash();
        assertEq(content, "Exclusive content!");
    }

    function testRevertIfUserViewsWithoutPaying() public {
        vm.expectRevert("Access denied: Pay first");
        vm.prank(user);
        payPerView.viewContentHash();
    }

    function testWithdrawFromSingleFunder() public {
        vm.prank(user);
        payPerView.payToView{value: SEND_VALUE}();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalanceBefore = address(payPerView).balance;

        vm.prank(owner);
        payPerView.withdraw();

        uint256 ownerBalanceAfter = owner.balance;

        assertEq(address(payPerView).balance, 0);
        assertEq(payPerView.getAddressToAmountPaid(user), 0);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + contractBalanceBefore);
    }
}
