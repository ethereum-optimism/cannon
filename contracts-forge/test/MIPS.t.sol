pragma solidity ^0.7.3;
pragma abicoder v2;

import { Test } from "forge-std/Test.sol";
import { MIPS } from "../src/MIPS.sol";
import { MIPSMemory } from "../src/MIPSMemory.sol";
import { FFI } from "./utils/FFI.sol";

contract MIPS_ExecwTrie_Test is Test {
    MIPS internal m;
    MIPSMemory internal mm;
    FFI internal ffi;

    struct TrieTest {
        bytes32 root;
        bytes32[] hashes;
        string[] preimages;
    }

    TrieTest internal trieAdd;
    TrieTest internal oracle;

    function setUp() public {
        // Create MIPS contracts
        m = new MIPS();
        mm = m.m();

        // Deploy FFI helper
        ffi = new FFI();

        // Pull in our trie data
        // (For some reason, we can't parse the whole struct at once, so we do it in pieces.)

        string memory trieAddStr = vm.readFile("./test/constants/trieAdd.json");
        trieAdd.root = abi.decode(vm.parseJson(trieAddStr, ".root"), (bytes32));
        trieAdd.hashes = abi.decode(vm.parseJson(trieAddStr, ".hashes"), (bytes32[]));
        trieAdd.preimages = abi.decode(vm.parseJson(trieAddStr, ".preimages"), (string[]));

        string memory trieOracleStr = vm.readFile("./test/constants/trieOracle.json");
        oracle.root = abi.decode(vm.parseJson(trieOracleStr, ".root"), (bytes32));
        oracle.hashes = abi.decode(vm.parseJson(trieOracleStr, ".hashes"), (bytes32[]));
        oracle.preimages = abi.decode(vm.parseJson(trieOracleStr, ".preimages"), (string[]));
    }

    /**
     * @dev ...
     */
    function test_addShouldWork_succeeds() public {
        // Add all preimages
        addPreimages(trieAdd);

        bytes32 root = trieAdd.root;
        emit log_named_bytes32("starting root", root);

        for (uint256 i = 0; i < 12; i++) {
            root = m.Step(root);

            emit log_named_uint("i", i);
            emit log_named_bytes32("root", root);
        }
    }

    /**
     * @dev ...
     */
    function test_oracleShouldWork_succeeds() public {
        addPreimages(oracle);

        bytes32 root = oracle.root;
        emit log_named_bytes32("starting root", root);

        // "hello world" is the oracle
        mm.AddPreimage("hello world", 0);

        uint256 pc = 0;
        uint256 out1;
        uint256 out2;

        while (pc != 0x5ead0000) {
            root = m.Step(root);

            pc = mm.ReadMemory(root, 0xc0000080);
            out1 = mm.ReadMemory(root, 0xbffffff4);
            out2 = mm.ReadMemory(root, 0xbffffff8);

            // Logs
            emit log_named_bytes32("root", root);
            emit log_named_uint("pc", pc);
            emit log_named_uint("out1", out1);
            emit log_named_uint("out2", out2);
        }

        assertEq(out1, 1);
        assertEq(out2, 1);
    }

    /**
     * @dev Utility function to add all preimages contained in a [TrieTest]
     * to the [MIPSMemory] contract.
     *
     * TODO: There's honestly no need for FFI here- can just pre-compute the
     * encoded preimages in the JSON files and not do it at runtime.
     */
    function addPreimages(TrieTest storage trieData) internal {
        uint256 length = trieData.preimages.length;
        for (uint256 i = 0; i < length; i++) {
            mm.AddTrieNode(ffi.base64ToBin(trieData.preimages[i]));
        }
    }
}
