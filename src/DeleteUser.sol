// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

/**
 * This contract starts with 1 ether.
 * Your goal is to steal all the ether in the contract.
 *
 */
contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] public users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }
    // 1

    function withdraw(uint256 index) external {
        User storage user = users[index]; // ref point {1, "alice"}
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        uint256 amountUser1 = users[0].amount;
        address addrUser1 = users[0].addr;

        console.log("ADDR_USER_1:", addrUser1);
        console.log("AMOUNT_USER_1:", amountUser1);
        console.log("--------------------------------");

        if (users.length > 1) {
            uint256 amountUser2 = users[1].amount;
            address addrUser2 = users[1].addr;

            console.log("ADDR_USER_2:", addrUser2);
            console.log("AMOUNT_USER_2:", amountUser2);
            console.log("--------------------------------");
        }

        msg.sender.call{value: amount}("");
    }
}
