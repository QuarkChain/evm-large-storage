// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SlotHelper.sol";

contract SlotHelperTest{
    mapping(bytes32=>bytes32) public metadatas;
    function put(bytes32 key, bytes memory data) public {
        metadatas[key] = SlotHelper.putRaw(key, data);
    }

    function get(bytes32 key) public view returns(bytes memory res){
        // uint datalen = SlotHelper.decodeLen(metadatas[key]);
        bytes32 md = metadatas[key];
        res = SlotHelper.getRaw(key,md);
    }

    function encodeMetadata(bytes memory data)public pure returns(bytes32){
        return SlotHelper.encodeMetadata(data);
    }

    function decodeMetadata(bytes32 mdata) public pure returns(uint,bytes32){
        return SlotHelper.decodeMetadata(mdata);
    }

    function decodeMetadata1(bytes32 mdata) public pure returns(uint,bytes memory){
        return SlotHelper.decodeMetadata1(mdata);
    }

    function encodeLen( uint datalen )public pure returns(bytes32){
        return SlotHelper.encodeLen(datalen);
    }

    function decodeLen(bytes32 mdata) public pure returns(uint res){
        res = SlotHelper.decodeLen(mdata);
    }

    function getLen(bytes32 key) public view returns(uint resLen){
        bytes32 mdata = metadatas[key];
        resLen = SlotHelper.decodeLen(mdata);
    }

    
}