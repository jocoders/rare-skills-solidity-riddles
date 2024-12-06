// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Governance} from "../src/Viceroy.sol";
import {OligarchyNFT} from "../src/Viceroy.sol";
import {CommunityWallet} from "../src/Viceroy.sol";
import {Attacker} from "../src/Viceroy.sol";

contract ViceroyTest is Test {
    Governance public governance;
    OligarchyNFT public oligarch;
    Attacker public attacker;

    uint256 constant ETH_AMOUNT = 10 ether;

    function setUp() public {
        attacker = new Attacker();
        oligarch = new OligarchyNFT(address(attacker));
        governance = new Governance{value: ETH_AMOUNT}(oligarch);
        address wallet = address(governance.communityWallet());
        assertEq(wallet.balance, ETH_AMOUNT, "Governance should have 10 ether");
        attacker.init(address(governance));
    }

    function testAttack2() public {
        uint256 attackerBalanceBefore = address(attacker).balance;
        attacker.attack();
        uint256 attackerBalanceAfter = address(attacker).balance;
        uint256 diff = attackerBalanceAfter - attackerBalanceBefore;

        assertTrue(diff == 10 ether, "Attacker should have gained at least 10 ether");
    }
}
