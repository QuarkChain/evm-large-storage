// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleNameService {
    mapping(bytes32 => address) public owners;
    mapping(bytes32 => address) public pointers;

    function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
        bytes32 b32;
        assembly {
            b32 := mload(add(data, 0x20))
        }
        return b32;
    }

    function claim(bytes32 node) public {
        require(owners[node] == address(0x0), "already claimed");
        owners[node] = msg.sender;
    }

    function claimBy(bytes memory name) public {
        claim(bytesToBytes32(name));
    }

    function pointerOf(bytes memory name) public view returns (address) {
        return pointers[bytesToBytes32(name)];
    }

    function setPointer(bytes32 node, address addr) public {
        require(owners[node] == msg.sender, "must be owner");
        pointers[node] = addr;
    }
}
