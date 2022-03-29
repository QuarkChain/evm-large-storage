// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorageHelper.sol";
import "./StorageSlotSelfDestructable.sol";

// Large storage manager to support arbitrarily-sized data with multiple chunk
contract LargeStorageManager {
    mapping(bytes32 => mapping(uint256 => address)) private keyToContract;

    function _putChunk(
        bytes32 key,
        uint256 chunkId,
        bytes memory data,
        uint256 value
    ) internal virtual {
        address addr = keyToContract[key][chunkId];
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        } else {
            require(
                chunkId == 0 || keyToContract[key][chunkId - 1] != address(0x0),
                "must replace or append"
            );
        }

        keyToContract[key][chunkId] = StorageHelper.putRaw(data, value);
    }

    function _getChunk(bytes32 key, uint256 chunkId)
        internal
        view
        virtual
        returns (bytes memory, bool)
    {
        address addr = keyToContract[key][chunkId];
        return StorageHelper.getRaw(addr);
    }

    function _chunkSize(bytes32 key, uint256 chunkId)
        internal
        view
        virtual
        returns (uint256, bool)
    {
        address addr = keyToContract[key][chunkId];
        return StorageHelper.sizeRaw(addr);
    }

    function _countChunks(bytes32 key) internal view virtual returns (uint256) {
        uint256 chunkId = 0;

        while (true) {
            address addr = keyToContract[key][chunkId];
            if (addr == address(0x0)) {
                break;
            }

            chunkId++;
        }

        return chunkId;
    }

    // Returns (size, # of chunks).
    function _size(bytes32 key)
        internal
        view
        virtual
        returns (uint256, uint256)
    {
        uint256 size = 0;
        uint256 chunkId = 0;

        while (true) {
            address addr = keyToContract[key][chunkId];
            (uint256 chunkSize, bool found) = StorageHelper.sizeRaw(addr);
            if (!found) {
                break;
            }

            size += chunkSize;
            chunkId++;
        }

        return (size, chunkId);
    }

    function _get(bytes32 key)
        internal
        view
        virtual
        returns (bytes memory, bool)
    {
        (uint256 size, uint256 chunkNum) = _size(key);
        if (chunkNum == 0) {
            return (new bytes(0), false);
        }

        bytes memory data = new bytes(size); // solidity should auto-align the memory-size to 32
        uint256 dataPtr;
        assembly {
            dataPtr := add(data, 0x20)
        }
        for (uint256 chunkId = 0; chunkId < chunkNum; chunkId++) {
            address addr = keyToContract[key][chunkId];
            (uint256 chunkSize, ) = StorageHelper.sizeRaw(addr);

            StorageHelper.getRawAt(addr, dataPtr);
            dataPtr += chunkSize;
        }

        return (data, true);
    }

    // Returns # of chunks deleted
    function _remove(bytes32 key) internal virtual returns (uint256) {
        uint256 chunkId = 0;

        while (true) {
            address addr = keyToContract[key][chunkId];
            if (addr == address(0x0)) {
                break;
            }

            StorageSlotSelfDestructable(addr).destruct();
            keyToContract[key][chunkId] = address(0x0);

            chunkId++;
        }

        return chunkId;
    }

    function _removeChunk(bytes32 key, uint256 chunkId)
        internal
        virtual
        returns (bool)
    {
        address addr = keyToContract[key][chunkId];
        if (addr == address(0x0)) {
            return false;
        }

        if (keyToContract[key][chunkId + 1] != address(0x0)) {
            // only the last chunk can be removed
            return false;
        }

        StorageSlotSelfDestructable(addr).destruct();
        keyToContract[key][chunkId] = address(0x0);

        return true;
    }
}
