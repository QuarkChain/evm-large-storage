// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StoreInSlot {

    function storeData(bytes memory data ) public returns(bool){

        uint datalen = data.length;      
        uint slot = 0;  

        for (uint index = 0 ; index < datalen + 32 ; index += 32){
            assembly{
                sstore(slot , mload(data))
                slot := add(slot,1)
                data := add(data,0x20)
            }
        }
        return true ;
    }

    function getData(uint slot) public view returns(bytes32 res){
        assembly{
            res := sload(slot)
        }
    }
}

/*
    前多少位放位图
    每32位可以放8k数据的位图
*/
contract StoreInSlotByDynamicArray{
    bytes32[] public datas;

    function storeDataFirst(bytes memory data) public  { 
        bytes32 v;
        uint len = data.length;
        for (uint i=0;i*32<len;i++){
            assembly{
                data := add(data,0x20)
                v := mload(data)
            }
            datas.push(v);
        }
    }
    function storeDataOverwrite(bytes memory data) public  { 
        bytes32 v;
        uint len = data.length;
        for (uint i=0;i*32<len;i++){
            assembly{
                data := add(data,0x20)
                v := mload(data)
            }
            datas[i] =v;
        }
    }

    function datalen()public view  returns(uint){
        return datas.length;
    }
}

contract StoreInSlotByStaticArray{
    uint constant DatasMaxLen = 1000000;
    bytes32[DatasMaxLen] public datas;   

    function storeData(bytes memory data) public  { 
        bytes32 v;
        uint len = data.length;
        for (uint i=0;i*32<len;i++){
            assembly{
                data := add(data,0x20)
                v := mload(data)
            }
            datas[i] = v;
        }
    }
}

contract StoreInSlotByMap{
   mapping(uint=>bytes32) public datas;

   function storeData(bytes memory data) public  {
        bytes32 v;
        uint len = data.length;
        for (uint i=0;i*32<len;i++){
            assembly{
                data := add(data,0x20)
                v := mload(data)
            }
            datas[i] = v;
        }
   }
}
