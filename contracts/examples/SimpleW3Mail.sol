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
        bytes uuid;
        bytes name;
        bytes fileType;
        bytes iv;
    }

    struct Email {
        uint256 time;
        bytes uuid;
        bytes from;
        bytes to;
        bytes title;
        bytes fileUuid;
    }

    struct User {
        bytes32 publicKey;
        address fdContract;

        bytes email;
        bytes driveEncrypt;
        bytes cipherIV;

        Email[] sentEmails;
        mapping(bytes => uint256) sentEmailIds;
        Email[] inboxEmails;
        mapping(bytes => uint256) inboxEmailIds;
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

    function sendEmail(bytes memory toEmail, bytes memory uuid, bytes memory title, bytes calldata encryptData, bytes memory fileUuid)
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
        email.fileUuid = fileUuid;

        // add email
        fromInfo.sentEmails.push(email);
        fromInfo.sentEmailIds[uuid] = fromInfo.sentEmails.length;
        toInfo.inboxEmails.push(email);
        toInfo.inboxEmailIds[uuid] = toInfo.inboxEmails.length;

        // write email
        FlatDirectory fileContract = FlatDirectory(fromInfo.fdContract);
        fileContract.writeChunk{value : msg.value}(getNewName('', uuid, bytes('message')), 0, encryptData);
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
        User storage info = userInfos[msg.sender];
        require(info.sentEmailIds[uuid] != 0, "Email does not exist");

        uint256 lastIndex = info.sentEmails.length - 1;
        uint256 removeIndex = info.sentEmailIds[uuid] - 1;
        bytes memory fileUuid = info.sentEmails[removeIndex].fileUuid;
        if (lastIndex != removeIndex) {
            info.sentEmails[removeIndex] = info.sentEmails[lastIndex];
            info.sentEmailIds[info.sentEmails[lastIndex].uuid] = removeIndex + 1;
        }
        info.sentEmails.pop();
        delete info.sentEmailIds[uuid];


        FlatDirectory fileContract = FlatDirectory(info.fdContract);
        // remove emial context
        fileContract.remove(getNewName('', uuid, bytes('message')));
        // remove file
        fileContract.remove(getNewName('file/', uuid, fileUuid));
        fileContract.refund();
        payable(msg.sender).transfer(address(this).balance);
    }

    function removeInboxEmail(bytes memory uuid) public {
        User storage info = userInfos[msg.sender];
        require(info.inboxEmailIds[uuid] != 0, "Email does not exist");

        uint256 lastIndex = info.inboxEmails.length - 1;
        uint256 removeIndex = info.inboxEmailIds[uuid] - 1;
        if (lastIndex != removeIndex) {
            info.inboxEmails[removeIndex] = info.inboxEmails[lastIndex];
            info.inboxEmailIds[info.inboxEmails[lastIndex].uuid] = removeIndex + 1;
        }
        info.inboxEmails.pop();
        delete info.inboxEmailIds[uuid];
    }

    function removEmails(uint256 types, bytes[] memory uuids) public {
        if (types == 0) {
            for (uint256 i; i < uuids.length; i++) {
                removeSentEmail(uuids[i]);
            }
        } else {
            for (uint256 i; i < uuids.length; i++) {
                removeInboxEmail(uuids[i]);
            }
        }
    }

    function getNewName(string memory label, bytes memory dir, bytes memory name) public pure returns (bytes memory) {
        return abi.encodePacked(label, dir, '/', name);
    }

    function getInboxEmails() public view
        returns (
            uint256[] memory times,
            bytes[] memory uuids,
            bytes[] memory emails,
            bytes[] memory titles,
            bytes[] memory fileUuids,
            bytes[] memory fileNames
        )
    {
        User storage info = userInfos[msg.sender];
        uint256 length = info.inboxEmails.length;
        times = new uint256[](length);
        uuids = new bytes[](length);
        emails = new bytes[](length);
        titles = new bytes[](length);
        fileUuids = new bytes[](length);
        fileNames = new bytes[](length);
        for (uint256 i; i < length; i++) {
            times[i] = info.inboxEmails[i].time;
            uuids[i] = info.inboxEmails[i].uuid;
            emails[i] = info.inboxEmails[i].from;
            titles[i] = info.inboxEmails[i].title;

            fileUuids[i] = info.inboxEmails[i].fileUuid;
            fileNames[i] = info.files[fileUuids[i]].name;
        }
    }

    function getSentEmails() public view
        returns (
            uint256[] memory times,
            bytes[] memory uuids,
            bytes[] memory emails,
            bytes[] memory titles,
            bytes[] memory fileUuids,
            bytes[] memory fileNames
        )
    {
        User storage info = userInfos[msg.sender];
        uint256 length = info.sentEmails.length;
        times = new uint256[](length);
        uuids = new bytes[](length);
        emails = new bytes[](length);
        titles = new bytes[](length);
        fileUuids = new bytes[](length);
        fileNames = new bytes[](length);
        for (uint256 i; i < length; i++) {
            times[i] = info.sentEmails[i].time;
            uuids[i] = info.sentEmails[i].uuid;
            emails[i] = info.sentEmails[i].from;
            titles[i] = info.sentEmails[i].title;

            fileUuids[i] = info.sentEmails[i].fileUuid;
            fileNames[i] = info.files[fileUuids[i]].name;
        }
    }

    function getEmailContent(bytes memory uuid, uint256 chunkId) public view returns (bytes memory data) {
        FlatDirectory fileContract = FlatDirectory(userInfos[msg.sender].fdContract);
        (data,) = fileContract.readChunk(getNewName('', uuid, bytes('message')), chunkId);
    }

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
        returns (
            bytes32 publicKey,
            bytes memory email,
            bytes memory encryptData,
            bytes memory iv
        )
    {
        return (userInfos[user].publicKey, userInfos[user].email, userInfos[user].driveEncrypt, userInfos[user].cipherIV);
    }

    function getPublicKeyByEmail(bytes memory email) public view returns (bytes32 publicKey) {
        (publicKey,,,) = getUserInfo(emailList[email]);
    }

    // function getChunkHash(bytes memory uuid, uint256 chunkId) public view returns (bytes32) {
    //     return fileFD.getChunkHash(getNewName(msg.sender, uuid), chunkId);
    // }

    // function countChunks(bytes memory uuid) public view returns (uint256) {
    //     return fileFD.countChunks(getNewName(msg.sender, uuid));
    // }
}
