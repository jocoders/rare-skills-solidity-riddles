// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    RewardToken,
    NftToStake,
    Depositoor,
    DepositoorAttacker,
    CreateDepositoorAttackerFactory
} from "../src/RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken public rewardToken;
    NftToStake public nftToStake;
    Depositoor public depositoor;
    DepositoorAttacker public depositoorAttacker;
    CreateDepositoorAttackerFactory public createDepositoorAttackerFactory;

    uint256 SALT = 4946472957456;

    function setUp() public {
        createDepositoorAttackerFactory = new CreateDepositoorAttackerFactory();
        address attacker = createDepositoorAttackerFactory.getAddress(SALT, address(this));
        nftToStake = new NftToStake(attacker);

        depositoor = new Depositoor(IERC721(address(nftToStake)));
        rewardToken = new RewardToken(address(depositoor));
        depositoor.setRewardToken(IERC20(address(rewardToken)));
        depositoorAttacker = createDepositoorAttackerFactory.deploy(SALT, address(this));
        depositoorAttacker.init(depositoor, nftToStake);

        assertEq(attacker, address(depositoorAttacker), "attacker address mismatch");
    }

    function testExploit() public {
        depositoorAttacker.depositNft();
        bool isUsed = depositoor.alreadyUsed(42);
        assertTrue(isUsed, "token should be used");

        vm.warp(block.timestamp + 6 days);
        depositoorAttacker.claimEarnings();
        uint256 balanceDepositoor = rewardToken.balanceOf(address(depositoor));
        uint256 balanceAttacker = rewardToken.balanceOf(address(depositoorAttacker));

        assertEq(balanceDepositoor, 0, "depositoor should have 0 balance");
        assertGt(balanceAttacker, 10e18, "attacker should have more than 10 tokens");
    }
}
