// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 存储方法
library SlotHelper{
    uint internal constant ADDRBITLEN = 160;

    function putRaw(bytes32 key , bytes memory data)
        internal 
        returns(bytes32 mdata)
    {
        uint len = data.length;
        for (uint index = 0 ; index * 32 < len ; index ++){
            assembly{
                data := add(data,0x20)
                mstore(0,add(key,index))
                let slot := keccak256(0,0x20)
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

    function addrToBytes32(address addr)internal pure returns(bytes32){
        assembly{
            mstore(0,addr)
            return(0,0x20)
        }
    }

    function addrToBytes32_1(address addr)internal pure returns(bytes32){
        return bytes32(uint256(uint160(addr)));

    }

    function bytes32ToAddr(bytes32 bt) internal pure returns(address){
        assembly{
            mstore(0,bt)
            return(0,0x20)
        }
    }

    function bytes32ToAddr_1(bytes32 bt) internal pure returns(address){
        return address(uint160(uint256(bt)));
    }

}