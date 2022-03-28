// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotHelper.sol";
import "../StorageHelper.sol";
import "../StorageSlotSelfDestructable.sol";
import "../LargeStorageManager.sol";

contract OptimizedLargeStorageManager {
    uint internal constant SLOTLIMIT = 220; 
    mapping(bytes32 => mapping(uint256 => bytes32)) public keyToContract;
    mapping(bytes32=>mapping(uint256=>mapping(uint256=>bytes32))) public keyToSlot;

    function _putChunk(
        bytes32 key,
        uint256 chunkId,
        bytes memory data,
        uint256 value
    ) internal {

        bytes32 metadata = keyToContract[key][chunkId];
        address addr = SlotHelper.bytes32ToAddr(metadata);
        if (metadata == bytes32(0)){
             require(
                    chunkId == 0 || keyToContract[key][chunkId - 1] != bytes32(0x0),
                    "must replace or append"
            );
        }

        if (!SlotHelper.isInSlot(metadata)){
            if (addr != address(0x0)) {
                // remove the KV first if it exists
                StorageSlotSelfDestructable(addr).destruct();
            } 
        }
        
        // store data and rewrite metadata
        if (data.length > SLOTLIMIT){
            keyToContract[key][chunkId] = SlotHelper.addrToBytes32(StorageHelper.putRaw(data, value));
        }else{
            keyToContract[key][chunkId] = SlotHelper.putRaw(keyToSlot[key][chunkId],data);
        }
    }

    function _getChunk(bytes32 key, uint256 chunkId)
        internal
        view
        returns (bytes memory, bool)
    {
        bytes32 metadata = keyToContract[key][chunkId];
        address addr = SlotHelper.bytes32ToAddr(metadata);
        if (SlotHelper.isInSlot(metadata)){
            bytes memory res  = SlotHelper.getRaw(keyToSlot[key][chunkId], metadata);
            return (res,true);
        }else{
            return StorageHelper.getRaw(addr);
        }

    }

    function _chunkSize(bytes32 key, uint256 chunkId)
        internal
        view
        returns (uint256, bool)
    {
        bytes32 metadata = keyToContract[key][chunkId];
        address addr = SlotHelper.bytes32ToAddr(metadata);

        if (metadata == bytes32(0)){
            return (0,false);
        }else if (SlotHelper.isInSlot(metadata)){
            uint len  = SlotHelper.decodeLen(metadata);
            return (len,true);
        }else{
            return StorageHelper.sizeRaw(addr);
        }
    }

    function _countChunks(bytes32 key) internal view returns (uint256) {
        uint256 chunkId = 0;

        while (true) {
            bytes32 metadata = keyToContract[key][chunkId];
            if (metadata == bytes32(0x0)) {
                break;
            }

            chunkId++;
        }

        return chunkId;
    }

     // Returns (size, # of chunks).
    function _size(bytes32 key) internal view returns (uint256, uint256) {
        uint256 size = 0;
        uint256 chunkId = 0;

        while (true) {
            (uint256 chunkSize, bool found) = _chunkSize(key,chunkId);
            if (!found) {
                break;
            }

            size += chunkSize;
            chunkId++;
        }

        return (size, chunkId);
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
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
            bytes32 metadata = keyToContract[key][chunkId];
            address addr = SlotHelper.bytes32ToAddr(metadata);

            uint256 chunkSize = 0;
            if (SlotHelper.isInSlot(metadata)){
                //todo
                chunkSize = SlotHelper.decodeLen(metadata);
                SlotHelper.getRawAt(keyToSlot[key][chunkId], metadata,dataPtr);

            }else{
                (chunkSize, ) = StorageHelper.sizeRaw(addr);
                StorageHelper.getRawAt(addr, dataPtr);
            }

            dataPtr += chunkSize;
        }

        return (data, true);
    }

        // Returns # of chunks deleted
    function _remove(bytes32 key) internal returns (uint256) {
        uint256 chunkId = 0;

        while (true) {
            bytes32 metadata = keyToContract[key][chunkId];
            address addr = SlotHelper.bytes32ToAddr(metadata);
            if (metadata == bytes32(0x0)) {
                break;
            }

            if (!SlotHelper.isInSlot(metadata)){
                // remove new contract
                StorageSlotSelfDestructable(addr).destruct();
            }

            keyToContract[key][chunkId] = bytes32(0x0);

            chunkId++;
        }

        return chunkId;
    }

    function _removeChunk(bytes32 key, uint256 chunkId)
        internal
        returns (bool)
    {
        bytes32 metadata = keyToContract[key][chunkId];
        address addr = SlotHelper.bytes32ToAddr(metadata);
        if (metadata == bytes32(0x0)) {
            return false;
        }

        if (keyToContract[key][chunkId + 1] != bytes32(0x0)) {
            // only the last chunk can be removed
            return false;
        }

        if (!SlotHelper.isInSlot(metadata)){
            // remove new contract
            StorageSlotSelfDestructable(addr).destruct();
        }
        
        keyToContract[key][chunkId] = bytes32(0x0);

        return true;
    }


}