// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlatDirectory.sol";

contract SimpleFilebox {
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct FilesInfo {
        uint256 fileSize;
        string[] urls;
        mapping(bytes32 => uint256) ids;
    }

    FlatDirectory public fileFD;

    address public owner;
    string public gateway;

    mapping(bytes32 => address) public fileAuthors;
    mapping(address => FilesInfo) files;

    constructor(string memory _gateway) {
        owner = msg.sender;
        gateway = _gateway;
        fileFD = new FlatDirectory(0);
    }

    receive() external payable {
    }

    function setGateway(string calldata _gateway) public isOwner {
        gateway = _gateway;
    }

    function write(bytes memory name, bytes calldata data) public payable {
        writeChunk(name, 0, data);
    }

    function writeChunk(bytes memory name, uint256 chunkId, bytes calldata data) public payable {
        bytes32 nameHash = keccak256(name);
        require(fileAuthors[nameHash] == address(0) || fileAuthors[nameHash] == msg.sender, "File is Exist");

        fileFD.writeChunk{value: msg.value}(name, chunkId, data);

        if (fileAuthors[nameHash] == address(0)) {
            FilesInfo storage info = files[msg.sender];
            info.urls.push(getUrl(name));
            info.ids[nameHash] = info.fileSize;
            info.fileSize++;
        }
        fileAuthors[nameHash] = msg.sender;
    }

    function remove(bytes memory name) public returns (uint256) {
        bytes32 nameHash = keccak256(name);
        require(fileAuthors[nameHash] == msg.sender, "Only author can delete");

        uint256 id = fileFD.remove(name);
        fileFD.refund();
        payable(msg.sender).transfer(address(this).balance);

        FilesInfo storage info = files[msg.sender];
        delete info.urls[info.ids[nameHash]];
        delete info.ids[nameHash];
        info.fileSize--;
        fileAuthors[nameHash] = address(0);

        return id;
    }

    function getChunkHash(bytes memory name, uint256 chunkId) public view returns (bytes32) {
        return fileFD.getChunkHash(name, chunkId);
    }

    function countChunks(bytes memory name) public view returns (uint256) {
        return fileFD.countChunks(name);
    }

    function getUrl(bytes memory name) public view returns (string memory) {
        return string(abi.encodePacked(
                gateway,
                'filebox.w3q/',
                name
            ));
    }

    function getUserFiles() public view virtual returns (string[] memory) {
        return getAuthorFiles(msg.sender);
    }

    function getAuthorFiles(address author) public view returns (string[] memory) {
        string[] memory localData = files[author].urls;
        uint256 size = files[author].fileSize;
        string[] memory urls = new string[](size);
        for (uint256 i; i < localData.length; i++) {
            if(keccak256(bytes(localData[i])) != keccak256(bytes(''))) {
                urls[i] = localData[i];
            }
        }
        return urls;
    }
}
