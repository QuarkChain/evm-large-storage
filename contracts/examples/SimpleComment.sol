// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";

contract SimpleComment is SimpleFlatDirectory {

    constructor() SimpleFlatDirectory(0) {}

    function uintToBytes(uint v) internal pure returns (bytes memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return s;
    }

    function uintToString(uint v) internal pure returns (string memory) {
        return string(uintToBytes(v));
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
            add(m, 20),
            xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function bytesToAddress(bytes memory bys) internal pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function writeComment(uint256 id, bytes memory content) public payable {
        write(abi.encodePacked(string(uintToString(id)), "comment"), content);
    }

    function writeOwner(uint256 id, address owner) public payable {
        write(abi.encodePacked(string(uintToString(id)), "owner"), addressToBytes(owner));
    }

    function writeTimestamp(uint256 id, uint256 timestamp) public payable {
        write(abi.encodePacked(string(uintToString(id)), "timestamp"), uintToBytes(timestamp));
    }

    function getComment(uint256 id) public view returns (bytes memory) {
        return files(abi.encodePacked(string(uintToString(id)), "comment"));
    }

    function getOwner(uint256 id) public view returns (address) {
        bytes memory content = files(abi.encodePacked(string(uintToString(id)), "owner"));
        return bytesToAddress(content);
    }

    function getTimestamp(uint256 id) public view returns (bytes memory) {
        return files(abi.encodePacked(string(uintToString(id)), "timestamp"));
    }

    function deleteComment(uint256 removeId, uint256 replaceId) public {
        bytes memory ownerId = abi.encodePacked(string(uintToString(replaceId)), "owner");
        bytes memory timestampId = abi.encodePacked(string(uintToString(replaceId)), "timestamp");
        bytes memory commentId = abi.encodePacked(string(uintToString(replaceId)), "comment");

        if (removeId != replaceId) {
            bytes memory owner = files(ownerId);
            write(abi.encodePacked(string(uintToString(removeId)), "owner"), owner);
            bytes memory timestamp = files(timestampId);
            write(abi.encodePacked(string(uintToString(removeId)), "timestamp"), timestamp);
            bytes memory comment = files(commentId);
            write(abi.encodePacked(string(uintToString(removeId)), "comment"), comment);
        }

        remove(ownerId);
        remove(timestampId);
        remove(commentId);
    }
}

