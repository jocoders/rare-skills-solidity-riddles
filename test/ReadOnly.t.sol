// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ReadOnlyPool, VulnerableDeFiContract, ReadOnlyPoolAttacker} from "../src/ReadOnly.sol";

contract ReadOnlyTest is Test {
    ReadOnlyPool pool;
    VulnerableDeFiContract defiContract;
    ReadOnlyPoolAttacker attacker;

    function setUp() public {
        pool = new ReadOnlyPool();
        defiContract = new VulnerableDeFiContract(pool);
        attacker = new ReadOnlyPoolAttacker(pool, defiContract);

        pool.addLiquidity{value: 1 ether}();
        vm.deal(address(attacker), 10 ether);
    }

    function test_exploit() public {
        console.log("START");
        attacker.addLiquidity();
        attacker.exploit();
        console.log("FINISH");
    }
}
