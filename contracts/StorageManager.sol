// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageHelper.sol";
import "./StorageSlotSelfDestructable.sol";

contract StorageManager {
    mapping(bytes32 => address) internal keyToContract;

    function _put(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        address addr = keyToContract[key];
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }

        keyToContract[key] = StorageHelper.putRaw(data, value);
    }

    function _put2(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        address addr = keyToContract[key];
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }

        keyToContract[key] = StorageHelper.putRaw2(key, data, value);
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        address addr = keyToContract[key];
        return StorageHelper.getRaw(addr);
    }

    function _remove(bytes32 key) internal returns (bool) {
        address addr = keyToContract[key];
        if (addr == address(0x0)) {
            return false;
        }

        StorageSlotSelfDestructable(addr).destruct();
        return true;
    }
}
