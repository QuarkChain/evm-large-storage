// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 存储方法
library SlotHelper{
    uint256 internal constant SLOTDATA_RIGHT_SHIFT = 32;
    uint256 internal constant LEN_OFFSET = 224;
    uint256 internal constant FIRST_SLOT_DATA_SIZE = 28;
    

    function putRaw(mapping (uint256 => bytes32) storage slots, bytes memory datas)
        internal 
        returns(bytes32 mdata)
    {
        // warn: if data as ptr to move,your should keep "data.length" by another ptr
        uint len = datas.length;
        mdata = encodeMetadata(datas);
        if (len > FIRST_SLOT_DATA_SIZE){
            for (uint256 i = 0; i < (len - FIRST_SLOT_DATA_SIZE +32 - 1) / 32; i ++) {
                bytes32 value;
                uint256 ptr;
                assembly {
                    ptr := add(datas, add(0x20,FIRST_SLOT_DATA_SIZE))
                    ptr := add(ptr, mul(i,32))
                    value := mload(ptr)
                }
                slots[i] = value;
            } 
        }
    }

    function encodeMetadata(bytes memory data) internal pure returns(bytes32 medata){
        uint256 datLen = data.length;
        uint256 value;
        assembly{
            value := mload(add(data,0x20))
        }

        datLen = datLen << LEN_OFFSET;
        value = value >> SLOTDATA_RIGHT_SHIFT;
        
        medata = bytes32(value|datLen);
    }

    function decodeMetadata(bytes32 mdata) internal pure returns(uint len ,bytes32 data){
        len = decodeLen(mdata);
        data =  mdata << SLOTDATA_RIGHT_SHIFT;
    }

    function decodeMetadataToData(bytes32 mdata) internal pure returns(uint len ,bytes memory data){
        len = decodeLen(mdata);
        mdata =  mdata << SLOTDATA_RIGHT_SHIFT;
        data = new bytes(len);
        assembly{
            mstore(add(data,0x20),mdata)
        }
    }

    function getRaw(mapping (uint256 => bytes32) storage slots,bytes32 mdata) internal view returns(bytes memory data){
        uint datalen ;
        (datalen, data)= decodeMetadataToData(mdata);

        if (datalen > FIRST_SLOT_DATA_SIZE){
            uint ptr = 0;
            bytes32 value = 0;
            for (uint256 i = 0; i < (datalen - FIRST_SLOT_DATA_SIZE + 32 - 1) / 32; i ++) {
                value = slots[i];
                assembly{
                    ptr := add(data, add(0x20,FIRST_SLOT_DATA_SIZE))
                    ptr := add(ptr, mul(i,32))
                    // ptr := add(ptr,0x20)

                    mstore(ptr,value)
                }
            }
        }
    } 

    function getRawAt(mapping (uint256 => bytes32) storage slots,bytes32 mdata, uint256 memoryPtr)
        internal
        view
        returns (uint256 datalen, bool found)
    {
        bytes32 datapart;
        (datalen, datapart)= decodeMetadata(mdata);

        uint dataPtr = memoryPtr;
        assembly{
            mstore(dataPtr,datapart)
        }

        if (datalen > FIRST_SLOT_DATA_SIZE){
            uint ptr = 0;
            bytes32 value = 0;
            for (uint256 i = 0; i < (datalen - FIRST_SLOT_DATA_SIZE + 32 - 1) / 32; i ++) {
                value = slots[i];
                assembly{
                    ptr := add(dataPtr, FIRST_SLOT_DATA_SIZE)
                    ptr := add(ptr, mul(i,32))
                    // ptr := add(ptr,0x20)

                    mstore(ptr,value)
                }
            }
        }

        found = true;
    }

    function isInSlot(bytes32 mdata) internal pure returns(bool succeed){
        uint exist = uint256(mdata) >> LEN_OFFSET;
        return exist > 0;
    }

    function encodeLen( uint datalen ) internal pure returns(bytes32 res){
        res = bytes32(datalen  << LEN_OFFSET); 
    }

    function decodeLen(bytes32 mdata) internal pure returns(uint res){
        res = uint(mdata) >> LEN_OFFSET;
    }

    function addrToBytes32(address addr)internal pure returns(bytes32){
        return bytes32(uint256(uint160(addr)));

    }

    function bytes32ToAddr(bytes32 bt) internal pure returns(address){
        return address(uint160(uint256(bt)));
    }

}