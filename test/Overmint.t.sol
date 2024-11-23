// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { Overmint, OvermintAttacker } from '../src/Overmint.sol';

contract OvermintTest is Test {
  Overmint victim;
  OvermintAttacker attacker;

  function setUp() public {
    victim = new Overmint();
    attacker = new OvermintAttacker(address(victim));
  }

  function testAttack() public {
    attacker.attack();
    assertTrue(victim.success(address(attacker), attacker.TOKEN_ID()), 'must have 5 NFTs');
    assertTrue(attacker.txCount() < 3, 'must exploit in two transactions or less');
  }
}
