// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageManager.sol";

contract StorageManagerTest is StorageManager {
    function get(bytes32 key) public view returns (bytes memory) {
        (bytes memory data, ) = _get(key);
        return data;
    }

    function put(bytes32 key, bytes memory data) public {
        _put(key, data);
    }
}