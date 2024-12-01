// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Overmint1ERC1155, Overmint1ERC1155Attacker} from "../src/Overmint1-ERC1155.sol";

/**
 * @title Overmint1 ERC1155 Attack Test
 * @notice Demonstrates exploitation of recursive mint in ERC1155 token
 *
 * @dev The vulnerability exists because:
 * - Contract calls onERC1155Received after each mint
 * - No reentrancy protection in place
 * - amountMinted check can be bypassed through recursion
 *
 * Attack flow:
 * 1. Initial mint() creates first NFT
 * 2. This triggers onERC1155Received callback
 * 3. Inside callback, we check balance and mint again if < 5
 * 4. Recursion continues until we have 5 NFTs
 * 5. All mints happen in a single transaction
 */
contract Overmint1ERC1155Test is Test {
    Overmint1ERC1155 victim;
    Overmint1ERC1155Attacker attacker;

    function setUp() public {
        victim = new Overmint1ERC1155();
        attacker = new Overmint1ERC1155Attacker(address(victim));
    }

    function testAttack() public {
        attacker.attack();
        assertTrue(victim.success(address(attacker), attacker.TOKEN_ID()), "must have 5 NFTs");
        assertTrue(attacker.txCount() < 3, "must exploit in two transactions or less");
    }
}
