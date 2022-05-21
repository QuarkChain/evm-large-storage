// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotHelper.sol";

contract SlotHelperTest {
    mapping(bytes32 => bytes32) public metadatas;
    mapping(bytes32 => mapping(uint256 => bytes32)) public slots;

    function put(bytes32 key, bytes memory data) public {
        metadatas[key] = SlotHelper.putRaw(slots[key], data);
    }

    function get(bytes32 key) public view returns (bytes memory res) {
        bytes32 md = metadatas[key];
        res = SlotHelper.getRaw(slots[key], md);
    }

    function encodeMetadata(bytes memory data) public pure returns (bytes32) {
        return SlotHelper.encodeMetadata(data);
    }

    function decodeMetadata(bytes32 mdata) public pure returns (uint256, bytes32) {
        return SlotHelper.decodeMetadata(mdata);
    }

    function decodeMetadata1(bytes32 mdata) public pure returns (uint256, bytes memory) {
        return SlotHelper.decodeMetadataToData(mdata);
    }

    function encodeLen(uint256 datalen) public pure returns (bytes32) {
        return SlotHelper.encodeLen(datalen);
    }

    function decodeLen(bytes32 mdata) public pure returns (uint256 res) {
        res = SlotHelper.decodeLen(mdata);
    }

    function getLen(bytes32 key) public view returns (uint256 resLen) {
        bytes32 mdata = metadatas[key];
        resLen = SlotHelper.decodeLen(mdata);
    }
}
