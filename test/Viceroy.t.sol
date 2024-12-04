// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Governance} from "../src/Viceroy.sol";
import {OligarchyNFT} from "../src/Viceroy.sol";
import {CommunityWallet} from "../src/Viceroy.sol";
import {DeployWithCreate3} from "../src/Viceroy.sol";
import {Create2Factory} from "../src/Viceroy.sol";

contract ViceroyTest is Test {
    Governance public governance;
    OligarchyNFT public oligarch;

    DeployWithCreate3 public deployedContract2;
    Create2Factory public factory;
    address public attacker;
    address public voter;

    uint256 SALT = 347309243929;

    function setUp() public {
        attacker = makeAddr("attacker");
        voter = makeAddr("voter");
        oligarch = new OligarchyNFT(attacker);
        governance = new Governance{value: 10 ether}(oligarch);

        factory = new Create2Factory();

        address wallet = address(governance.communityWallet());
        assertEq(wallet.balance, 10 ether, "Governance should have 10 ether");
    }

    // function getAddress(bytes memory bytecode, uint _salt) private view returns (address) {
    //   bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
    //   return address(uint160(uint(hash)));
    // }

    // // function getBytecode(address _governance) private pure returns (bytes memory) {
    // //   bytes memory bytecode = type(DeployWithCreate2).creationCode;
    // //   return abi.encodePacked(bytecode, abi.encode(_governance));
    // // }

    // function getBytecode(address _governance) private pure returns (bytes memory bytecode) {
    //   bytecode = abi.encodePacked(type(DeployWithCreate2).creationCode, abi.encode(_governance));
    // }

    function deploy() public {
        bytes memory bytecode = factory.getBytecode(attacker, address(governance));
        address addr = factory.getAddress(bytecode, SALT);
        governance.appointViceroy(addr, 1);

        factory.deploy(SALT, attacker, address(governance));
        deployedContract2 = factory.deployedContract();

        // console.log('addr', addr);
        // console.log('deployedContract2', address(deployedContract2));
        assertEq(addr, address(deployedContract2), "Deployed contract should be the same");
    }

    function testAttack() public {
        // //uint256 nonceBefore = vm.getNonce(attackerWallet);
        vm.startPrank(attacker);
        deploy();
        vm.stopPrank();
        // assertEq(address(communityWallet).balance, 0, 'Community wallet should be empty after attack');
        // //assertEq(vm.getNonce(attackerWallet) - nonceBefore, 1, 'Must exploit in one transaction');
        // uint256 attackerBalance = address(attackerWallet).balance;
        // assertTrue(attackerBalance >= 10 ether, 'Attacker should have gained at least 10 ether');
    }
}
