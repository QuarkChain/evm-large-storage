// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 存储方法
library SlotHelper{
    uint constant ADDRBITLEN = 160;

    function putRaw(bytes32 key , bytes memory data)
        internal 
        returns(bytes32 mdata)
    {
        for (uint index = 0 ; index * 32 < data.length ; index ++){
            bytes32 keydata = bytes32(0);
            assembly{
                data := add(data,0x20)
                mstore(keydata,add(key,index))
                let slot := keccak256(keydata,0x20)
                sstore(slot,mload(data))
            }
        }
        mdata = encodeLen(data.length);
    }

    function getRaw(bytes32 key , uint datalen) internal view returns(bytes memory res) {
        res = new bytes(datalen);
        uint ptr;
        assembly{
            ptr := add(res,0x20)
        }

        for (uint index = 0 ; index * 32 < datalen ; index ++){
             bytes32 keydata = bytes32(0);
            assembly{
                mstore(keydata,add(key,index))
                let slot := keccak256(keydata,0x20)
                let cdata := sload(slot)
                
                mstore(ptr,cdata)
                ptr := add(ptr,0x20)
            }
        }
    }

    function encodeLen( uint datalen ) internal pure returns(bytes32 res){
        assembly{
            res := shl(ADDRBITLEN,datalen)
        }
    }

    function isInSlot(bytes32 mdata) internal pure returns(bool succeed){
        uint exist;
        assembly{
            let res := shr(ADDRBITLEN,mdata)
            exist := iszero(res)
        }

        if (exist == 1){
            succeed = true ;
        }else{
            succeed = false;
        }
    }

    function decodeLen(bytes32 mdata) internal pure returns(uint res){
         assembly{
            res := shr(ADDRBITLEN,mdata)
        }
    }

}