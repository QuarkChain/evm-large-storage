// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC5018.sol";
import "./IERCBlob.sol";

interface EthStorageContract {
    function putBlob(bytes32 key, uint256 blobIdx, uint256 length) external payable;

    function get(bytes32 key, uint256 off, uint256 len) external view returns (bytes memory);

    function remove(bytes32 key) external;

    function upfrontPayment() external view returns (uint256);
}

contract ERCBlob is IERC5018, IERCBlob {
    struct Blob {
        uint256 idv; // 0 start
        uint256 length;
        bytes32 blobKey;
    }

    struct Chunk {
        uint256 chunkSize;
        bytes32 chunkHash;
        Blob[] blobs;
    }

    address public owner;
    EthStorageContract public storageContract;

    mapping(bytes32 => Chunk[]) internal keyToChunk;

    constructor(address storageAddress) {
        owner = msg.sender;
        storageContract = EthStorageContract(storageAddress);
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "must from owner");
        owner = newOwner;
    }

    function _chunkSize(bytes32 key, uint256 chunkId) internal view returns (uint256, bool) {
        if (_countChunks(key) == 0 || chunkId >= _countChunks(key)) {
            return (0, false);
        }
        uint256 size_ = keyToChunk[key][chunkId].chunkSize;
        return (size_, true);
    }

    function _countChunks(bytes32 key) internal view returns (uint256) {
        return keyToChunk[key].length;
    }

    function _size(bytes32 key) internal view returns (uint256, uint256) {
        uint256 size_ = 0;
        uint256 chunkId_ = 0;
        while (true) {
            (uint256 chunkSize_, bool found) = _chunkSize(key, chunkId_);
            if (!found) {
                break;
            }
            size_ += chunkSize_;
            chunkId_++;
        }

        return (size_, chunkId_);
    }

    function _getChunk(bytes32 key, uint256 chunkId) internal view returns (bytes memory, bool) {
        bytes memory data = new bytes(0);
        Chunk memory chunk = keyToChunk[key][chunkId];
        uint256 length = chunk.blobs.length;
        if (length < 1) {
            return (data, false);
        }

        for (uint8 i = 0; i < length; i++) {
            bytes memory temp = storageContract.get(chunk.blobs[i].blobKey, i, chunk.blobs[i].length);
            data = bytes.concat(data, temp);
        }
        return (data, true);
    }

    function _get(bytes32 key) internal view returns (bytes memory, bool) {
        (, uint256 chunkNum) = _size(key);
        if (chunkNum == 0) {
            return (new bytes(0), false);
        }

        bytes memory data = new bytes(0);
        for (uint256 chunkId = 0; chunkId < chunkNum; chunkId++) {
            (bytes memory temp, bool state) = _getChunk(key, chunkId);
            if (!state) {
                break;
            }
            data = bytes.concat(data, temp);
        }

        return (data, true);
    }

    function _removeChunk(bytes32 key, uint256 chunkId) internal returns (bool) {
        require(_countChunks(key) - 1 == chunkId, "only the last chunk can be removed");

        Chunk storage chunk = keyToChunk[key][chunkId];
        uint256 length = chunk.blobs.length;
        for (uint8 i = 0; i < length; i++) {
            storageContract.remove(chunk.blobs[i].blobKey);
        }
        keyToChunk[key].pop();
        return true;
    }

    function _remove(bytes32 key, uint256 chunkId) internal returns (uint256) {
        require(_countChunks(key) > 0, "the file has no content");

        for (uint256 i = _countChunks(key) - 1; i >= chunkId; i--) {
            _removeChunk(key, i);
        }

        return chunkId;
    }

    function _preparePut(bytes32 key, uint256 chunkId) private {
        require(chunkId <= _countChunks(key), "must replace or append");
        if (chunkId < _countChunks(key)) {
            // replace, delete old blob
            Chunk storage chunk = keyToChunk[key][chunkId];
            uint256 length = chunk.blobs.length;
            for (uint8 i = 0; i < length; i++) {
                storageContract.remove(chunk.blobs[i].blobKey);
            }
            delete chunk.blobs;
        }
    }

    function _putChunk(
        bytes32 key,
        uint256 value,
        uint256 chunkId,
        bytes32 chunkHash,
        uint256[] memory blobLengths
    ) internal {
        require(blobLengths.length < 3 && blobLengths.length > 0, "invalid blob length");
        uint256 cost = storageContract.upfrontPayment();
        require(value >= cost * blobLengths.length, "insufficient balance");

        _preparePut(key, chunkId);

        Chunk storage chunk = keyToChunk[key][chunkId];
        // put blob
        uint256 size_ = 0;
        uint256 length = blobLengths.length;
        for (uint8 i = 0; i < length; i++) {
            // TODO
            bytes32 blobKey = keccak256(abi.encodePacked(chunkHash, i));

            storageContract.putBlob{value : cost}(blobKey, i, blobLengths[i]);
            chunk.blobs.push(Blob(i, blobLengths[i], blobKey));
            size_ += blobLengths[i];
        }
        chunk.chunkSize = size_;
        chunk.chunkHash = chunkHash;
    }



    // interface methods
    function write(bytes memory name, bytes memory data) external payable {}

    function read(bytes memory name) public view virtual override returns (bytes memory, bool) {
        return _get(keccak256(name));
    }

    function size(bytes memory name) public view virtual override returns (uint256, uint256) {
        return _size(keccak256(name));
    }

    function remove(bytes memory name) public virtual override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name), 0);
    }

    function countChunks(bytes memory name) public view virtual override returns (uint256) {
        return _countChunks(keccak256(name));
    }

    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes memory data
    ) external payable {}

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

    function truncate(bytes memory name, uint256 chunkId) public virtual override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name), chunkId);
    }

    function refund() public override {
        require(msg.sender == owner, "must from owner");
        payable(owner).transfer(address(this).balance);
    }

    function destruct() public override {
        require(msg.sender == owner, "must from owner");
        selfdestruct(payable(owner));
    }

    function getChunkHash(bytes memory name, uint256 chunkId) public view returns (bytes32) {
        bytes32 key = keccak256(name);
        if (_countChunks(key) == 0 || chunkId >= _countChunks(key)) {
            return bytes32(0);
        }
        return keyToChunk[key][chunkId].chunkHash;
    }

    // Chunk-based large storage methods
    function writeChunkBlob(
        bytes memory name,
        uint256 chunkId,
        bytes32 chunkHash,
        uint256[] memory blobLengths
    ) public payable virtual override {
        require(msg.sender == owner, "must from owner");
        _putChunk(keccak256(name), msg.value, chunkId, chunkHash, blobLengths);
        refund();
    }

    function upfrontPayment() external view returns (uint256) {
        return storageContract.upfrontPayment();
    }
}
