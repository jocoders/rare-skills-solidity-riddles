// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// contract DeployWithCreate3 {
//   address public owner;
//   constructor(address _owner) {
//     owner = _owner;
//   }
// }

// contract Create2Factory {
//   DeployWithCreate3 public deployedContract;

//   function deploy(uint _salt, address _owner) external {
//     deployedContract = new DeployWithCreate3{ salt: bytes32(_salt) }(_owner);
//   }

//   function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
//     bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));
//     return address(uint160(uint(hash)));
//   }

//   function getBytecode(address _owner) public pure returns (bytes memory) {
//     bytes memory bytecode = type(DeployWithCreate3).creationCode;
//     return abi.encodePacked(bytecode, abi.encode(_owner));
//   }
// }
