// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotHelper.sol";
import "../StorageHelper.sol";
import "../StorageSlotSelfDestructable.sol";

contract OptimizedStorageManager {
    uint8 internal constant NO_EXIST = 0;
    uint8 internal constant IN_SLOT = 1;
    uint8 internal constant IN_CONTRACT_CODE = 2;
    uint8 internal constant WHERE_STORE_ERROR = 255;

    uint256 internal constant SLOT_LIMIT = 220;
    mapping(bytes32 => bytes32) public keyToContract;
    mapping(bytes32 => mapping(uint256 => bytes32)) public keyToSlot;

    function _put(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        bytes32 metadata = keyToContract[key];

        if (!SlotHelper.isInSlot(metadata)) {
            address addr = SlotHelper.bytes32ToAddr(metadata);
            // Notify: No need to delete metadata here, because it will be rewritten later
            if (addr != address(0x0)) {
                // remove the KV first if it exists
                StorageSlotSelfDestructable(addr).destruct();
            }
        }

        if (data.length > SLOT_LIMIT) {
            // store in new contract
            keyToContract[key] = SlotHelper.addrToBytes32(
                StorageHelper.putRaw(data, value)
            );
        } else {
            // store in slot
            keyToContract[key] = SlotHelper.putRaw(keyToSlot[key], data);
        }
    }

    function _put2(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr(metadata);
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }

        if (data.length > SLOT_LIMIT) {
            // store in new contract
            keyToContract[key] = SlotHelper.addrToBytes32(
                StorageHelper.putRaw2(key, data, value)
            );
        } else {
            // store in slot
            keyToContract[key] = SlotHelper.putRaw(keyToSlot[key], data);
        }
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr(metadata);

        if (SlotHelper.isInSlot(metadata)) {
            bytes memory res = SlotHelper.getRaw(keyToSlot[key], metadata);
            return (res, true);
        } else {
            return StorageHelper.getRaw(addr);
        }
    }

    function _filesize(bytes32 key) internal view returns (uint256) {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr(metadata);

        if (metadata == bytes32(0)) {
            return 0;
        } else if (SlotHelper.isInSlot(metadata)) {
            return SlotHelper.decodeLen(metadata);
        } else {
            (uint256 size, ) = StorageHelper.sizeRaw(addr);
            return size;
        }
    }

    function _whereStore(bytes32 key) internal view returns (uint256) {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr(metadata);

        if (metadata == bytes32(0)) {
            return NO_EXIST;
        } else if (SlotHelper.isInSlot(metadata)) {
            return IN_SLOT;
        } else {
            (, bool found) = StorageHelper.sizeRaw(addr);
            if (found) {
                return IN_CONTRACT_CODE;
            } else {
                // happen error
                return WHERE_STORE_ERROR;
            }
        }
    }

    function _remove(bytes32 key) internal returns (bool) {
        bytes32 metadata = keyToContract[key];

        if (metadata == bytes32(0)) {
            return false;
        }

        if (!SlotHelper.isInSlot(metadata)) {
            address addr = SlotHelper.bytes32ToAddr(metadata);
            if (addr != address(0x0)) {
                StorageSlotSelfDestructable(addr).destruct();
            }
        }

        // cover slot case
        keyToContract[key] = 0;
        return true;
    }
}
