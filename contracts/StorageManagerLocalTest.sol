// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageManagerLocalTest {
    mapping(bytes32 => bytes) localMap;

    // for gas metering
    function getWithoutView(bytes32 key) public returns (bytes memory) {
        return localMap[key];
    }

    function put(bytes32 key, bytes memory data) public {
        localMap[key] = data;
    }
}
