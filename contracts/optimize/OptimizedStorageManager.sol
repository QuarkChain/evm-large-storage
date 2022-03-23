// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotHelper.sol";
import "../StorageHelper.sol";
import "../StorageSlotSelfDestructable.sol";

contract OptimizedStorageManager {
    uint internal constant SLOTLIMIT = 192; 
    mapping(bytes32 => bytes32) public keyToContract;
    
    function _put(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {

        bytes32 metadata = keyToContract[key];

        address addr = SlotHelper.bytes32ToAddr_1(metadata);
        // Notify :No need to delete metadata here, because it will be rewritten later
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }
    
        if (data.length > SLOTLIMIT){
            // store in new contract
            keyToContract[key] = SlotHelper.addrToBytes32_1(StorageHelper.putRaw(data, value));
        }else{
            // store in slot
            keyToContract[key] = SlotHelper.encodeLen(data.length);
            SlotHelper.putRaw(key,data);
        }
        
    }

    function _put2(
        bytes32 key,
        bytes memory data,
        uint256 value
    ) internal {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr_1(metadata);
        if (addr != address(0x0)) {
            // remove the KV first if it exists
            StorageSlotSelfDestructable(addr).destruct();
        }

        if (data.length > SLOTLIMIT){
            // store in new contract
            keyToContract[key] = SlotHelper.addrToBytes32_1(StorageHelper.putRaw2(key , data, value));
        }else{
            // store in slot
            keyToContract[key] = SlotHelper.encodeLen(data.length);
            SlotHelper.putRaw(key,data);
        }

    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr_1(metadata);

        // 判断从哪里获取数据
        if (SlotHelper.isInSlot(metadata)){
            bytes memory res  = SlotHelper.getRaw(key, SlotHelper.decodeLen(metadata));
            return (res,true);
        }else{
            return StorageHelper.getRaw(addr);
        }

    }


    function _remove(bytes32 key) internal returns (bool) {
        bytes32 metadata = keyToContract[key];
        address addr = SlotHelper.bytes32ToAddr_1(metadata);

        if (metadata == bytes32(0)) {
            return false;
        }
        // todo : 添加条件判断
        if (addr != address(0x0)){
            StorageSlotSelfDestructable(addr).destruct();
        }

        // cover slot case
        keyToContract[key] =0;
        return true;
    }
}
