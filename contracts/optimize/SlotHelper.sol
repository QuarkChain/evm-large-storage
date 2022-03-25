// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 存储方法
library SlotHelper{
    uint internal constant RIGHTSLOTDATASHIFT = 32;
    uint internal constant LENOFFSET = 224;
    uint internal constant FIRSTSLOTDATASIZE = 28;
    

    function putRaw(bytes32 key , bytes memory data)
        internal 
        returns(bytes32 mdata)
    {
        // warn: if data as ptr to move,your should keep "data.length" by another ptr
        uint len = data.length;
        mdata = encodeMetadata(data);
        if (len > FIRSTSLOTDATASIZE){
            for (uint index = 0 ; index * 32 < len - FIRSTSLOTDATASIZE ; index ++){
                assembly{
                    data := add(data,0x20)
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)

                    //跟下一个字(memory)的数据进行拼接
                    let value1 := shl( LENOFFSET , mload(data))
                    let value2 := shr( RIGHTSLOTDATASHIFT , mload(add(data,0x20)))
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
            
            // just in stack 
            len := shl(LENOFFSET,len)
            value := shr(RIGHTSLOTDATASHIFT,value) 

            // just in 
            medata := or(len,value)
        }
    }

    function decodeMetadata(bytes32 mdata) internal pure returns(uint len ,bytes32 data){
        len = decodeLen(mdata);
        data =  mdata << RIGHTSLOTDATASHIFT;
    }

    function decodeMetadata1(bytes32 mdata) internal pure returns(uint len ,bytes memory data){
        len = decodeLen(mdata);
        mdata =  mdata << RIGHTSLOTDATASHIFT;
        data = new bytes(len);
        assembly{
            mstore(add(data,0x20),mdata)
        }
    }

    function getRaw(bytes32 key,bytes32 mdata) internal view returns(bytes memory res){
        uint datalen ;
        (datalen, res)= decodeMetadata1(mdata);
        if (datalen > FIRSTSLOTDATASIZE){
            uint ptr = 0;
            assembly{
                ptr := add(res,0x40) 
            }

            for (uint index = 0 ; index * 32 < datalen - FIRSTSLOTDATASIZE ; index ++){
                assembly{
                    
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)
                    let cdata := sload(slot)
                    
                    // 先拿4个字节跟前28字节数据拼
                    let value1 := shr(LENOFFSET,cdata)
                    value1 := or(mload(sub(ptr,0x20)),value1)
                    mstore(sub(ptr,0x20),value1)
                    
                    // 将剩下的28字节数据往前移动 4*8 bit位
                    let value2 := shl(RIGHTSLOTDATASHIFT , cdata)
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

        if (datalen > FIRSTSLOTDATASIZE){

            for (uint index = 0 ; index * 32 < datalen - FIRSTSLOTDATASIZE ; index ++){
                assembly{
                    mstore(0,add(key,index))
                    let slot := keccak256(0,0x20)
                    let cdata := sload(slot)
                    
                    // 先拿4个字节跟前28字节数据拼
                    let value1 := shr(LENOFFSET,cdata)
                    value1 := or(mload(sub(ptr,0x20)),value1)
                    mstore(sub(ptr,0x20),value1)
                    
                    // 将剩下的28字节数据往前移动 4*8 bit位
                    let value2 := shl(RIGHTSLOTDATASHIFT , cdata)
                    mstore(ptr,value2)

                    ptr := add(ptr,0x20)
                }
            }
        }

        found = true;
    }

    function isInSlot(bytes32 mdata) internal pure returns(bool succeed){
        uint exist = uint256(mdata) >> LENOFFSET;
        return exist > 0;
    }

    function encodeLen( uint datalen ) internal pure returns(bytes32 res){
        assembly{
            res := shl(LENOFFSET,datalen)
        }
    }

    function decodeLen(bytes32 mdata) internal pure returns(uint res){
         assembly{
            res := shr(LENOFFSET,mdata)
        }
    }

    function addrToBytes32(address addr)internal pure returns(bytes32){
        return bytes32(uint256(uint160(addr)));

    }

    function bytes32ToAddr(bytes32 bt) internal pure returns(address){
        return address(uint160(uint256(bt)));
    }

}