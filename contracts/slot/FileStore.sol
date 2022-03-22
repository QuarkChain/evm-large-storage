pragma solidity ^0.8.0;

import "./Bitmap.sol";
contract FileStore{
    Bitmap public _bitmap;

    constructor(address bitmap_){
        _bitmap = Bitmap(bitmap_);
    }

    struct FileInfo {
        uint128 starSlot;
        uint128 length;
    }
    mapping(string=>FileInfo) public Files ;

    function writeFile(string memory name,  bytes memory datas)public returns(uint sslot,uint eslot){
        (sslot,eslot) = _bitmap.getFreeSpaceByLen(datas.length);
        _bitmap.storeInExpectSlots(datas, sslot, eslot);
        
        Files[name].starSlot = uint128(sslot);
        Files[name].length = uint128(datas.length); 
    }

    function deleteFile(string memory name) public {
        require(Files[name].length!=0 ,"FILESTORE: file no exist");

        _bitmap.deleteSlotBylen(Files[name].starSlot, Files[name].length);
        delete(Files[name]);
    }

    function loadFile(string memory name) public view returns(bytes memory ){
        require(Files[name].length!=0 ,"FILESTORE: file no exist");
        return _bitmap.slotsDatas(Files[name].starSlot, Files[name].length);
    }

}