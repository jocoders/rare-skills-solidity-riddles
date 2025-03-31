// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// You've been approved to claim 1 ETH. Claim more than your fair share.
contract DoubleTake {
    address public signer;

    mapping(bytes => bool) used;
    mapping(address => uint256) public allowance;

    constructor(address _signer) payable {
        signer = _signer;
    }

    function claimAirdrop(address user, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 hash_ = keccak256(abi.encode(user, amount));
        bytes memory signature = abi.encodePacked(v, r, s);

        require(signer == ecrecover(hash_, v, r, s), "signature not accepted");
        require(!used[signature], "signature already used");
        used[signature] = true;

        (bool ok,) = user.call{value: amount}("");
        require(ok, "transfer failed");
    }
}
