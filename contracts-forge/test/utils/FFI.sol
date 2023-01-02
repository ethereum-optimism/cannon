pragma solidity ^0.7.3;
pragma abicoder v2;

import { Test } from "forge-std/Test.sol";

contract FFI is Test {
    function base64ToBin(string memory _in) external returns (bytes memory out) {
        string[] memory commands = new string[](4);
        commands[0] = "node";
        commands[1] = "./test/utils/lib.js";
        commands[2] = "base64ToBin";
        commands[3] = _in;

        out = abi.decode(vm.ffi(commands), (bytes));
    }
}
