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

contract MIPS_Memory_Test is Test {
    MIPSMemory internal mm;

    function setUp() public {
        mm = new MIPSMemory();
        mm.AddTrieNode(hex"80");
    }

    function test_writeFromNew_succeeds() public {
        bytes32 root = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

        writeMemory(root, 0, bytes32(uint256(1)), false);

        // Manually update stateHash.
        root = 0x6dd3e774e192c8a5fe89bc8d0fdba43884a20ecca8b9e60e288928a93c73ee40;

        writeMemory(root, 4, bytes32(uint256(2)), false);

        // Manually update stateHash.
        root = 0xeced287a5dd678487a24d5e58048fc44781d14077ddc3e295b1f459cd8cf4ad3;

        assertEq(uint256(mm.ReadMemory(root, 0)), 1);
        assertEq(uint256(mm.ReadMemory(root, 4)), 2);
    }

    function test_writeThree_succeeds() public {
        mm.AddTrieNode(hex"80");
        bytes32 root = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

        writeMemory(root, 0, bytes32(uint256(1)), false);

        // Manually update stateHash.
        root = 0x6dd3e774e192c8a5fe89bc8d0fdba43884a20ecca8b9e60e288928a93c73ee40;

        writeMemory(root, 4, bytes32(uint256(2)), false);

        // Manually update stateHash.
        root = 0xeced287a5dd678487a24d5e58048fc44781d14077ddc3e295b1f459cd8cf4ad3;

        writeMemory(root, 0x40, bytes32(uint256(3)), false);

        // Manually update stateHash.
        root = 0xe89a6791c93380078272c462b38d7b06656fb7e64acb1baf6494dd0a04f43628;

        assertEq(uint256(mm.ReadMemory(root, 0)), 1);
        assertEq(uint256(mm.ReadMemory(root, 4)), 2);
        assertEq(uint256(mm.ReadMemory(root, 0x40)), 3);
    }

    function test_writeOtherThree_succeeds() public {
        bytes32 root = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

        writeMemory(root, 0x7fffd00c, bytes32(uint256(1)), false);

        // Manually update stateHash.
        root = 0x84fd1bf56c187da60c37ce81178f45d26316b028e1a45c88c927f90f22b33d4c;

        writeMemory(root, 0x7fffd010, bytes32(uint256(2)), false);

        // Manually update stateHash.
        root = 0x111729ad885676061d192769ef17f81da7d4c1a93c836fd8ed0d13a5f329982c;

        writeMemory(root, 0x7fffcffc, bytes32(uint256(3)), false);

        // Manually update stateHash.
        root = 0x6a26dc2689ff7686aa42ed436ec50d310e365fc89a7b5f6ff31c65944ad3b83a;

        assertEq(uint256(mm.ReadMemory(root, 0x7fffd00c)), 1);
        assertEq(uint256(mm.ReadMemory(root, 0x7fffd010)), 2);
        assertEq(uint256(mm.ReadMemory(root, 0x7fffcffc)), 3);
    }

    function test_bugFoundFuzzing_succeeds() public {
        bytes32 root = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

        writeMemory(root, 0, bytes32(0), false);

        // Manually update stateHash.
        root = 0x254c5a8a7224d51601929756c9ef0600c2ecf8b42bbb9a022aaf697e5eb7bd05;

        writeMemory(root, 0, bytes32(uint256(1)), false);

        // Manually update stateHash.
        root = 0x6dd3e774e192c8a5fe89bc8d0fdba43884a20ecca8b9e60e288928a93c73ee40;

        writeMemory(root, 0, bytes32(uint256(2)), false);
    }

    // TODO: Currently, because the [MIPSMemory] contract does not return the new
    // stateHash, we can't replicate the fuzz test in foundry tests.
    //
    // This test will be implemented after some needed love to the contracts.
    function testFuzz_writeMemory_succeeds() public {
        // ....
    }

    // TODO: `writeMemory` needs to return the root that was emitted.
    // For now, we hard-code the expected stateHash after each `writeMemory` call.
    function writeMemory(bytes32 root, uint32 addr, bytes32 data, bool bytes_32) internal {
        if (bytes_32) {
            mm.WriteBytes32WithReceipt(root, addr, data);
        } else {
            mm.WriteMemoryWithReceipt(root, addr, uint32(uint256(data)));
        }
    }
}
