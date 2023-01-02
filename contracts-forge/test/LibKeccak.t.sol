pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";
import {MIPSMemory} from "../src/MIPSMemory.sol";

contract LibKeccak_Test is Test {
    MIPSMemory internal mm;

    function setUp() public {
        mm = new MIPSMemory();
    }

    /**
     * @dev Tests that LibKeccak correctly hashes data with a byte size in the range of [1, 135]
     */
    function testDiff_keccak_1to135blockSize_succeeds(uint256 _size) public {
        // Initiate preimage
        mm.AddLargePreimageInit(0);

        // Bound `_size` to [1, 135]
        _size = bound(_size, 1, 135);

        // Create our test case
        bytes memory testCase = new bytes(_size);
        // Fill `testCase` with `0x62` bytes
        for (uint256 i = 0; i < _size; i++) {
            testCase[i] = 0x62;
        }

        // Assert that the digests are equal
        (bytes32 outHash, , ) = mm.AddLargePreimageFinal(testCase);
        assertEq(outHash, keccak256(testCase));
    }

    /**
     * @dev Tests that LibKeccak correctly hashes data with a size of 136 bytes.
     */
    function testDiff_keccak_136blockSize_succeeds() public {
        // Create our test case
        bytes memory testCase = new bytes(136);
        testCase[0] = 0x61;

        // Set our preimage to the test case
        mm.AddLargePreimageUpdate(testCase);

        (bytes32 outHash, , ) = mm.AddLargePreimageFinal(new bytes(0));

        // Assert that the digests are equal
        assertEq(outHash, keccak256(testCase));
    }

    /**
     * @dev Tests that saving to the preimage oracle works as intended
     */
    function test_oracle_saveShouldWork_succeeds() public {
        // Init preimage
        mm.AddLargePreimageInit(4);

        // Test case data
        bytes memory data = bytes("hello world");
        bytes32 dataHash = keccak256(data);

        // Add the preimage of data
        (bytes32 outHash, uint64 len, uint64 _data) = mm.AddLargePreimageFinal(
            data
        );

        // Assert that the result of `AddLargePreimageFinal` is correct
        assertEq(outHash, dataHash);
        assertEq(len, 11);
        assertEq(_data, 0x6f20776f);

        // Save the hash's preimage in the oracle
        mm.AddLargePreimageFinalSaved(data);
        mm.AddPreimage(data, 0);

        // Check first type
        uint64 preLen = mm.GetPreimageLength(dataHash);
        uint64 pre = mm.GetPreimage(dataHash, 4);
        assertEq(preLen, 11);
        assertEq(pre, 0x6f20776f);

        // Check other type
        preLen = mm.GetPreimageLength(dataHash);
        pre = mm.GetPreimage(dataHash, 0);
        assertEq(preLen, 11);
        assertEq(pre, 0x68656c6c);
    }
}
