// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./lib/Lib_Keccak256.sol";
import "./interfaces/IMIPSMemory.sol";

contract MIPSMemory {
  // This state is global
  mapping(bytes32 => mapping (uint32 => uint64)) public state;

  // TODO: replace with mapping(bytes32 => mapping(uint, bytes4))
  // to only save the part we care about
  mapping(bytes32 => bytes) public preimage;

  function addPreimage(bytes calldata anything) public {
    preimage[keccak256(anything)] = anything;
  }

  // one per owner (at a time)
  mapping(address => uint64[25]) public largePreimage;
  // TODO: also track the offset into the largePreimage to know what to store

  function addLargePreimageInit() public {
    Lib_Keccak256.CTX memory c;
    Lib_Keccak256.keccak_init(c);
    largePreimage[msg.sender] = c.A;
  }

  // TODO: input 136 bytes, as many times as you'd like
  // Uses about 1M gas, 7352 gas/byte
  function addLargePreimageUpdate(uint64[17] calldata data) public {
    // sha3_process_block
    Lib_Keccak256.CTX memory c;
    c.A = largePreimage[msg.sender];
    for (uint i = 0; i < 17; i++) {
      c.A[i] ^= data[i];
    }
    Lib_Keccak256.sha3_permutation(c);
    largePreimage[msg.sender] = c.A;
  }

  // TODO: input <136 bytes and do the end of hash | 0x01 / | 0x80
  function addLargePreimageFinal() public view returns (bytes32) {
    Lib_Keccak256.CTX memory c;
    c.A = largePreimage[msg.sender];
    // TODO: do this properly and save the hash
    // when this is updated, it won't be "view"
    return bytes32((uint256(c.A[0]) << 192) |
                   (uint256(c.A[1]) << 128) |
                   (uint256(c.A[2]) << 64) |
                   (uint256(c.A[3]) << 0));
  }

  function addMerkleState(bytes32 stateHash, uint32 addr, uint32 value, string calldata proof) public {
    // Currently there is a compilation warning since `calldata proof` is not used. See TODO below however.
    // TODO: check proof
    state[stateHash][addr] = (1 << 32) | value;
  }

  function writeMemory(bytes32 stateHash, uint32 addr, uint32 value) public pure returns (bytes32) {
    // Currently there is a compilation warning since `uint32 value` is not used. In case we don't use it,
    // we should remove it.
    require(addr & 3 == 0, "write memory must be 32-bit aligned");
    // TODO: do the real stateHash mutation
    bytes32 newstateHash = keccak256(abi.encodePacked(stateHash));

    // note that zeros are never stored in the trie, so storing a 0 is a delete

    // no proof required, this is obviously right
    //state[newstateHash][addr] = (1 << 32) | value;

    return newstateHash;
  }

  // needed for preimage oracle
  function readBytes32(bytes32 stateHash, uint32 addr) public view returns (bytes32) {
    uint256 ret = 0;
    for (uint32 i = 0; i < 32; i += 4) {
      ret <<= 32;
      ret |= uint256(readMemory(stateHash, addr+i));
    }
    return bytes32(ret);
  }

  function readMemory(bytes32 stateHash, uint32 addr) public view returns (uint32) {
    require(addr & 3 == 0, "read memory must be 32-bit aligned");

    // zero register is always 0
    if (addr == 0xc0000000) {
      return 0;
    }

    // MMIO preimage oracle
    if (addr >= 0x31000000 && addr < 0x32000000) {
      bytes32 pihash = readBytes32(stateHash, 0x30001000);
      if (addr == 0x31000000) {
        return uint32(preimage[pihash].length);
      }
      uint offset = addr-0x31000004;
      uint8 a0 = uint8(preimage[pihash][offset]);
      uint8 a1 = uint8(preimage[pihash][offset+1]);
      uint8 a2 = uint8(preimage[pihash][offset+2]);
      uint8 a3 = uint8(preimage[pihash][offset+3]);
      return (uint32(a0) << 24) |
             (uint32(a1) << 16) |
             (uint32(a2) << 8) |
             (uint32(a3) << 0);
    }

    uint64 ret = state[stateHash][addr];
    require((ret >> 32) == 1, "memory was not initialized");
    return uint32(ret);
  }
}
