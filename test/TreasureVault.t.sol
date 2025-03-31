// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TreasureVault, Exploit} from "../src/TreasureVault.sol";

contract TreasureVaultTest is Test {
    TreasureVault public vault;
    Exploit public exploit;

    function setUp() public {
        vault = new TreasureVault();
        exploit = new Exploit();

        vm.deal(address(this), 10 ether);
    }

    function testExploit() public {
        vault.deposit{value: 9 ether}();
        uint256 balanceBefore = address(vault).balance;
        console.log("****balanceBefore", balanceBefore);

        exploit.exploit(address(vault));
        //console.log('****success', success);

        address owner = vault.owner();
        bool initialized = vault.initialized();

        uint256 data = vault.getData();

        (uint256 slot1, uint256 slot2) = vault.getSlot();

        console.log("INITIALIZED", initialized);

        console.log("THIS", address(this));
        console.log("EXPLOIT", address(exploit));
        console.log("NEW OWNER", owner);
        console.log("DATA", data);
        console.log("SLOT1", slot1);
        console.log("SLOT2", slot2);
    }
}
