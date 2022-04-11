// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IW3RC3.sol";
import "./LargeStorageManager.sol";

contract W3RC3 is IW3RC3, LargeStorageManager {
    address public owner;

    constructor(uint8 slotLimit) LargeStorageManager(slotLimit) {
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "must from owner");
        owner = newOwner;
    }

    // Large storage methods
    function write(bytes memory name, bytes memory data) public payable virtual override {
        require(msg.sender == owner, "must from owner");
        // TODO: support multiple chunks
        return _putChunk(keccak256(name), 0, data, msg.value);
    }

    function read(bytes memory name) public view virtual override returns (bytes memory, bool) {
        return _get(keccak256(name));
    }

    function size(bytes memory name) public view virtual override returns (uint256, uint256) {
        return _size(keccak256(name));
    }

    function remove(bytes memory name) public virtual override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name));
    }

    function countChunks(bytes memory name) public view virtual override returns (uint256) {
        return _countChunks(keccak256(name));
    }

    // Chunk-based large storage methods
    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes memory data
    ) public payable virtual override {
        require(msg.sender == owner, "must from owner");
        return _putChunk(keccak256(name), chunkId, data, msg.value);
    }

    function readChunk(bytes memory name, uint256 chunkId) public view virtual override returns (bytes memory, bool) {
        return _getChunk(keccak256(name), chunkId);
    }

    function chunkSize(bytes memory name, uint256 chunkId) public view virtual override returns (uint256, bool) {
        return _chunkSize(keccak256(name), chunkId);
    }

    function removeChunk(bytes memory name, uint256 chunkId) public virtual override returns (bool) {
        require(msg.sender == owner, "must from owner");
        return _removeChunk(keccak256(name), chunkId);
    }
}
