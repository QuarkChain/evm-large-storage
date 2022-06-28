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

    struct File {
        uint256 time;
        bytes name;
    }

    struct FilesInfo {
        uint256 length;
        File[] files;
        mapping(bytes32 => uint256) fileIds;
    }

    FlatDirectory public fileFD;

    address public owner;
    string public gateway;

    mapping(bytes32 => address) public fileAuthors;
    mapping(address => FilesInfo) fileInfos;

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

        if (fileAuthors[nameHash] == address(0)) {
            FilesInfo storage info = fileInfos[msg.sender];
            info.files.push(File(block.timestamp, name));
            info.fileIds[nameHash] = info.files.length - 1;
            info.length++;

            fileAuthors[nameHash] = msg.sender;
        }

        fileFD.writeChunk{value: msg.value}(name, chunkId, data);
    }

    function remove(bytes memory name) public returns (uint256) {
        bytes32 nameHash = keccak256(name);
        require(fileAuthors[nameHash] == msg.sender, "Only author can delete");

        uint256 id = fileFD.remove(name);
        fileFD.refund();
        payable(msg.sender).transfer(address(this).balance);

        FilesInfo storage info = fileInfos[msg.sender];
        delete info.files[info.fileIds[nameHash]];
        delete info.fileIds[nameHash];
        info.length--;

        delete fileAuthors[nameHash];
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
                'file.w3q/',
                name
            ));
    }

    function getAuthorFiles(address author)
    public view
    returns (
        uint256[] memory times,
        bytes[] memory names,
        string[] memory urls
    )
    {
        uint256 length = fileInfos[author].length;
        times = new uint256[](length);
        names = new bytes[](length);
        urls = new string[](length);

        uint256 step = 0;
        uint256 size = fileInfos[author].files.length;
        for (uint256 i; i < size; i++) {
            if(fileInfos[author].files[i].time != 0) {
                times[step] = fileInfos[author].files[i].time;
                names[step] = fileInfos[author].files[i].name;
                urls[step] = getUrl(names[step]);
                step++;
            }
        }
    }
}
