// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 存储方法
library SlotHelper{
    uint256 internal constant SLOTDATA_RIGHT_SHIFT = 32;
    uint256 internal constant LEN_OFFSET = 224;
    uint256 internal constant FIRST_SLOT_DATASIZE = 28;
    

    function putRaw(bytes32 key , bytes memory data)
        internal 
        returns(bytes32 mdata)
    {
        // warn: if data as ptr to move,your should keep "data.length" by another ptr
        uint len = data.length;
        mdata = encodeMetadata(data);
        if (len > FIRST_SLOT_DATASIZE){
            for (uint index = 0 ; index * 32 < len - FIRST_SLOT_DATASIZE ; index ++){
                assembly{
                    data := add(data,0x20)
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)

                    //Restructured data
                    let value1 := shl( LEN_OFFSET , mload(data))
                    let value2 := shr( SLOTDATA_RIGHT_SHIFT , mload(add(data,0x20)))
                    value1 := or(value1,value2)

                    sstore(slot,value1)
                }
            }
        }
    }

    function encodeMetadata(bytes memory data) internal pure returns(bytes32 medata){
        assembly{
            let len := mload(data)
            let value := mload(add(data,0x20))
            
            // operator in stack 
            len := shl(LEN_OFFSET,len)
            value := shr(SLOTDATA_RIGHT_SHIFT,value) 

            medata := or(len,value)
        }
    }

    function decodeMetadata(bytes32 mdata) internal pure returns(uint len ,bytes32 data){
        len = decodeLen(mdata);
        data =  mdata << SLOTDATA_RIGHT_SHIFT;
    }

    function decodeMetadata1(bytes32 mdata) internal pure returns(uint len ,bytes memory data){
        len = decodeLen(mdata);
        mdata =  mdata << SLOTDATA_RIGHT_SHIFT;
        data = new bytes(len);
        assembly{
            mstore(add(data,0x20),mdata)
        }
    }

    function getRaw(bytes32 key,bytes32 mdata) internal view returns(bytes memory res){
        uint datalen ;
        (datalen, res)= decodeMetadata1(mdata);
        if (datalen > FIRST_SLOT_DATASIZE){
            uint ptr = 0;
            assembly{
                ptr := add(res,0x40) 
            }

            for (uint index = 0 ; index * 32 < datalen - FIRST_SLOT_DATASIZE ; index ++){
                assembly{
                    
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)
                    let cdata := sload(slot)
                    
                    // Or the last 4 bytes of the current word with the first 28 bytes of the previous word
                    let value1 := shr(LEN_OFFSET,cdata)
                    value1 := or(mload(sub(ptr,0x20)),value1)
                    mstore(sub(ptr,0x20),value1)
                    
                    // Move the last 28 bytes of the current word forward by 32 bits
                    let value2 := shl(SLOTDATA_RIGHT_SHIFT , cdata)
                    mstore(ptr,value2)

                    ptr := add(ptr,0x20)
                }
            }
        }
    } 

    function getRawAt(bytes32 key,bytes32 mdata, uint256 memoryPtr)
        internal
        view
        returns (uint256 datalen, bool found)
    {
        bytes32 datapart;
        (datalen, datapart)= decodeMetadata(mdata);

        uint ptr = memoryPtr;
        assembly{
            mstore(ptr,datapart)
            ptr := add(ptr,0x20) 
        }

        if (datalen > FIRST_SLOT_DATASIZE){

            for (uint index = 0 ; index * 32 < datalen - FIRST_SLOT_DATASIZE ; index ++){
                assembly{
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)
                    let cdata := sload(slot)
                    
                    // Or the last 4 bytes of the current word with the first 28 bytes of the previous word
                    let value1 := shr(LEN_OFFSET,cdata)
                    value1 := or(mload(sub(ptr,0x20)),value1)
                    mstore(sub(ptr,0x20),value1)
                    
                    // Move the last 28 bytes of the current word forward by 32 bits
                    let value2 := shl(SLOTDATA_RIGHT_SHIFT , cdata)
                    mstore(ptr,value2)

                    ptr := add(ptr,0x20)
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