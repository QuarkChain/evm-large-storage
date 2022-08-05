// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./FlatDirectory.sol";


contract SimpleW3Mail {
    using Strings for uint256;

    modifier isRegistered() {
        require(userInfos[msg.sender].fdContract != address(0), "Email is not register");
        _;
    }

    struct File {
        uint256 time;
        bytes name;
        bytes fileType;
        bytes iv;
    }

    struct Email {
        uint256 time;
        bytes from;
        bytes to;
        bytes uuid;
        bytes title;
        bytes messageName;
        File file;
    }

    struct User {
        bytes32 publicKey;
        address fdContract;

        bytes email;
        bytes driveEncrypt;
        bytes cipherIV;

        Email[] sentEmails;
        mapping(bytes32 => uint256) sentEmailIds;
        Email[] receiveEmails;
        mapping(bytes32 => uint256) receiveEmailIds;
        mapping(bytes => File) files;
    }

    mapping(bytes => address) public emailList;
    mapping(address => User) userInfos;

    receive() external payable {}

    function register(bytes32 publicKey, bytes memory email, bytes memory encryptData, bytes memory iv) public {
        require(emailList[email] == address(0), "Email is registered");
        User storage user = userInfos[msg.sender];
        require(user.fdContract == address(0), "Address is registered");

        user.email = email;
        user.publicKey = publicKey;
        FlatDirectory fileContract = new FlatDirectory(0);
        user.fdContract = address(fileContract);
        user.driveEncrypt = encryptData;
        user.cipherIV = iv;

        emailList[email] = msg.sender;
    }

    function sendEmail(
        bytes memory toEmail, bytes memory uuid,
        bytes memory title, bytes calldata encryptData,
        bytes memory fileId
    )
    public
    payable
    isRegistered
    {
        address toAddress = emailList[toEmail];
        require(toAddress != address(0), "Email is not register");

        User storage fromInfo = userInfos[msg.sender];
        User storage toInfo = userInfos[toAddress];

        // create email
        Email memory email;
        email.time = block.timestamp;
        email.from = fromInfo.email;
        email.to = toEmail;
        email.uuid = uuid;
        email.title = title;
        email.messageName = getNewName(uuid, bytes('message'));
        if(keccak256(fileId) != keccak256('')) {
            email.file = fromInfo.files[fileId];
        }

        // add email
        bytes32 uuidHash = keccak256(uuid);
        fromInfo.sentEmails.push(email);
        fromInfo.sentEmailIds[uuidHash] = fromInfo.sentEmails.length;
        toInfo.receiveEmails.push(email);
        toInfo.receiveEmailIds[uuidHash] = toInfo.receiveEmails.length;

        // write email
        FlatDirectory fileContract = FlatDirectory(fromInfo.fdContract);
        fileContract.writeChunk{value: msg.value}(email.messageName, 0, encryptData);
    }

    // function writeChunk(
    //     bytes memory uuid, bytes memory name,
    //     bytes memory fileType, uint256 chunkCount,
    //     uint256 chunkId, bytes memory iv, bytes calldata data
    // )
    //     public
    //     payable
    // {
    //     bytes32 uuidHash = keccak256(uuid);
    //     FilesInfo storage info = fileInfos[msg.sender];
    //     if (info.fileIds[uuidHash] == 0) {
    //         // first add file
    //         info.files.push(File(block.timestamp, chunkCount, uuid, name, fileType, iv));
    //         info.fileIds[uuidHash] = info.files.length;
    //     }

    //     fileFD.writeChunk{value: msg.value}(getNewName(msg.sender, uuid), chunkId, data);
    // }

    function removeSentEmail(bytes memory uuid) public {
        bytes32 uuidHash = keccak256(uuid);
        User storage info = userInfos[msg.sender];
        require(info.sentEmailIds[uuidHash] != 0, "Email does not exist");

        uint256 lastIndex = info.sentEmails.length - 1;
        uint256 removeIndex = info.sentEmailIds[uuidHash] - 1;
        File memory removeFile = info.sentEmails[removeIndex].file;
        if (lastIndex != removeIndex) {
            info.sentEmails[removeIndex] = info.sentEmails[lastIndex];
            info.sentEmailIds[keccak256(info.sentEmails[lastIndex].uuid)] = removeIndex + 1;
        }
        info.sentEmails.pop();
        delete info.sentEmailIds[uuidHash];


        FlatDirectory fileContract = FlatDirectory(info.fdContract);
        fileContract.remove(getNewName(uuid, bytes('message')));
        if(keccak256(removeFile.name) != keccak256('')) {
            fileContract.remove(getNewName(uuid, removeFile.name));
        }
        fileContract.refund();
        payable(msg.sender).transfer(address(this).balance);
    }

    function removeSents(bytes[] memory uuids) public {
        for (uint256 i; i < uuids.length; i++) {
            removeSentEmail(uuids[i]);
        }
    }

    function removeReceiveEmail(bytes memory uuid) public {
        bytes32 uuidHash = keccak256(uuid);
        User storage info = userInfos[msg.sender];
        require(info.receiveEmailIds[uuidHash] != 0, "Email does not exist");

        uint256 lastIndex = info.receiveEmails.length - 1;
        uint256 removeIndex = info.receiveEmailIds[uuidHash] - 1;
        if (lastIndex != removeIndex) {
            info.receiveEmails[removeIndex] = info.receiveEmails[lastIndex];
            info.receiveEmailIds[keccak256(info.receiveEmails[lastIndex].uuid)] = removeIndex + 1;
        }
        info.receiveEmails.pop();
        delete info.receiveEmailIds[uuidHash];
    }

    function removReceives(bytes[] memory uuids) public {
        for (uint256 i; i < uuids.length; i++) {
            removeReceiveEmail(uuids[i]);
        }
    }

    function getNewName(bytes memory dir,bytes memory name) public pure returns (bytes memory) {
        return abi.encodePacked(
            dir,
            '/',
            name
        );
    }

    // function getFileInfos()
    //     public
    //     view
    //     returns (
    //         uint256[] memory times,
    //         bytes[] memory uuids,
    //         bytes[] memory names,
    //         bytes[] memory types
    //     )
    // {
    //     uint256 length = fileInfos[msg.sender].files.length;
    //     times = new uint256[](length);
    //     uuids = new bytes[](length);
    //     names = new bytes[](length);
    //     types = new bytes[](length);
    //     for (uint256 i; i < length; i++) {
    //         times[i] = fileInfos[msg.sender].files[i].time;
    //         uuids[i] = fileInfos[msg.sender].files[i].uuid;
    //         names[i] = fileInfos[msg.sender].files[i].name;
    //         types[i] = fileInfos[msg.sender].files[i].fileType;
    //     }
    // }

    // function getFileInfo(bytes memory uuid)
    //     public
    //     view
    //     returns(
    //         uint256 realChunkCount,
    //         uint256 chunkCount,
    //         uint256 time,
    //         bytes memory name,
    //         bytes memory fileType,
    //         bytes memory iv
    //     )
    // {
    //     uint256 count = countChunks(uuid);
    //     bytes32 uuidHash = keccak256(uuid);
    //     FilesInfo storage info = fileInfos[msg.sender];
    //     uint256 index = info.fileIds[uuidHash] - 1;
    //     File memory file = info.files[index];
    //     return (count, file.chunkCount, file.time, file.name, file.fileType, file.iv);
    // }

    // function getFile(bytes memory uuid, uint256 chunkId) public view returns(bytes memory) {
    //     (bytes memory data, ) = fileFD.readChunk(getNewName(msg.sender, uuid), chunkId);
    //     return data;
    // }

    function getUserInfo(address user) public view
        returns(
            bytes32 publicKey,
            bytes memory email,
            bytes memory encryptData,
            bytes memory iv
        )
    {
        User storage info = userInfos[user];
        return (info.publicKey, info.email, info.driveEncrypt, info.cipherIV);
    }

    function getPublicKeyByEmail(bytes memory email) public view returns(bytes32 publicKey) {
        address user = emailList[email];
        (publicKey,,,) = getUserInfo(user);
    }

    // function getChunkHash(bytes memory uuid, uint256 chunkId) public view returns (bytes32) {
    //     return fileFD.getChunkHash(getNewName(msg.sender, uuid), chunkId);
    // }

    // function countChunks(bytes memory uuid) public view returns (uint256) {
    //     return fileFD.countChunks(getNewName(msg.sender, uuid));
    // }
}
