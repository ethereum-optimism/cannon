// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IMIPSMemory.sol";

/**
 * @dev Interface for the implemented MIPS (Microprocessor without Interlocked Pipelined Stages) architecture.
 */
interface IMIPS {
    // TODO: Reflect all implemented functions.

    /**
     * @dev Returns the state hash as bytes32.
     */
    function step(bytes32 stateHash) external view returns (bytes32);
    
    /**
     * @dev Returns the MIPS memory.
     * See {IMIPSMemory.sol}.
     */
    function m() external pure returns (IMIPSMemory);

    // TODO: Reflect all implemented events.
}
