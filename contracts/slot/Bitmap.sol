pragma solidity ^0.8.0;

contract Bitmap{
    uint256 public constant BitmapSlot = 1000000000000000;

    constructor() {

    }

    //empty: return 1 ;no empry: return 0
    function isEmptySlots(uint sslot,uint eslot)public view returns(uint256 succeed) {
        uint tmp;
        for (uint index = sslot ; index < eslot ;index ++){
            tmp += 2**index;
        }

        assembly{
            let _bitmap := sload(BitmapSlot)

            // zero ,succeed =1
            succeed := iszero(and(_bitmap,tmp))
        }
    }

    function storeInExpectSlots(bytes memory data,uint sslot,uint eslot) public {
        require(isEmptySlots(sslot,eslot)==1 ,"BITMAP: no empty slots");
        uint len = data.length;
        // (sslot,eslot) = getFreeSpaceByLen(len);
        uint currentSlot =sslot;
        for (uint i=0;i*32<len;i++) {
            assembly{
                data:= add(data,0x20)
                sstore(currentSlot,mload(data))
                currentSlot := add(currentSlot,1)
            }   
        }

        require(currentSlot == eslot ,"BITMAP: currentSlot!=eslot");
        // mark bitmap [ sslot , eslot )
        uint tmp ;
        for (uint ptr = sslot; ptr < eslot ;ptr++){
            tmp += 2**ptr;
        }
        assembly{
            let newBitmapVal := or(sload(BitmapSlot),tmp)
            sstore(BitmapSlot,newBitmapVal)
        }  
    }
    // under 8k
    function store(bytes memory data)public returns(uint sslot,uint eslot){
        uint len = data.length;
        (sslot,eslot) = getFreeSpaceByLen(len);
        uint currentSlot =sslot;
        for (uint i=0;i*32<len;i++) {
            assembly{
                data:= add(data,0x20)
                sstore(currentSlot,mload(data))
                currentSlot := add(currentSlot,1)
            }   
        }

        require(currentSlot == eslot ,"BITMAP: currentSlot!=eslot");

        // mark bitmap
        uint tmp ;
        for (uint ptr = sslot; ptr < eslot ;ptr++){
            tmp += 2**ptr;
        }
        assembly{
            let newBitmapVal := or(sload(BitmapSlot),tmp)
            sstore(BitmapSlot,newBitmapVal)
        }  
    }

    
    function deleteSlot(uint sslot,uint eslot)public {
        uint tmp;
        for (uint index = sslot ; index < eslot ;index ++){
            tmp += 2**index;
        }

        assembly{
            let _bitmap := sload(BitmapSlot)
            tmp := not(tmp)

            _bitmap := and(tmp,_bitmap)
            sstore(BitmapSlot,_bitmap)
        }
    }
    function deleteSlotBylen(uint sslot,uint datalen)public {
        uint eslot = endSlot(sslot, datalen);
        deleteSlot(sslot,eslot);
    }

    function getFreeSpaceByLen(uint datalen)public view returns(uint,uint){
        uint needslots  = datalen / 32;
        if (datalen % 32 != 0) {
            needslots ++;
        }
        return getFreeSpace(needslots);
    }

    // return: [begin,end)
    function getFreeSpace(uint needSlotNum)public view returns(uint,uint) {
        // 遍历bitMap slot找到可以存储
        uint tmp = 2 ** needSlotNum - 1;
        bytes32 _bitmap;
        assembly{
            _bitmap := sload(BitmapSlot)
        }

        bytes32 res;
        uint index;
        uint succeed;
        for (index = 0;index < 256 - needSlotNum;index++) {
            //iszero(x)  1 if x == 0, 0 otherwise
            assembly{
                res := and(_bitmap,shl(index,tmp))

                res := shr(index,res)
                res := shl(sub(256,needSlotNum),res)
                succeed := iszero(res)
            }

            if (succeed == 1){
                break;
            }
        }

        if (succeed != 1){
            // can not find free space
            return(0,0);
        }else{
            // succeed!
           return(index,index+needSlotNum);
        }

    }

    function bitmap() public view returns(bytes32 res){
        assembly{
            res := sload(BitmapSlot)
        }
    }

    function getslot(uint index) public view returns(bytes32 res){
        assembly{
            res := sload(index)
        }
    }

    function slotsDatas(uint sslot,uint datalen) public view returns(bytes memory){

        uint eslot = endSlot(sslot, datalen);
        uint ptr;
        bytes memory datas = new bytes(datalen);
        assembly{
            ptr := datas
            ptr := add(ptr,0x20)
        }

        for (sslot;sslot<eslot;sslot++){
            assembly{
                mstore(ptr,sload(sslot))
                ptr := add(ptr,0x20)
            }
        }
        return datas;
    }

    function endSlot(uint sslot,uint datalen) internal pure returns(uint eslot){
        uint needslots  = datalen / 32;
        if (datalen % 32 != 0) {
            needslots ++;
        }
        eslot =sslot+ needslots;
    }

    
}