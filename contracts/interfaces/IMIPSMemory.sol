// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @dev Interface for the read and write functionality of the MIPS (Microprocessor without Interlocked Pipelined Stages) memory.
 */
interface IMIPSMemory {
    // TODO: Reflect all implemented functions.
    
    /**
     * @dev Returns the MIPS memory as unit32 value type.
     */
    function readMemory(bytes32 stateHash, uint32 addr) external view returns (uint32);

    /**
     * @dev Returns the MIPS memory bytes as bytes32 value type.
     */
    function readBytes32(bytes32 stateHash, uint32 addr) external view returns (bytes32);

    /**
     * @dev Writes the MIPS memory.
     */
    function writeMemory(bytes32 stateHash, uint32 addr, uint32 val) external pure returns (bytes32);

    // TODO: Reflect all implemented events.
}
