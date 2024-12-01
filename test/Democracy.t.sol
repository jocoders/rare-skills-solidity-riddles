// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Democracy} from "../src/Democracy.sol";

contract DemocracyTest is Test {
    Democracy public victimContract;
    address public attacker;

    function setUp() public {
        attacker = makeAddr("attacker");

        uint256 value = 1 ether;

        victimContract = new Democracy{value: value}();
    }

    function testExploit() public {
        vm.startPrank(attacker);
        vm.stopPrank();

        assertEq(address(victimContract).balance, 0, "Contract balance should be zero");
    }
}
