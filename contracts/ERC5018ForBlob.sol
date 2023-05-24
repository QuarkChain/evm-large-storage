// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC5018ForBlob.sol";

interface EthStorageContract {
    function putBlob(bytes32 key, uint256 blobIdx, uint256 length) external payable;

    function get(bytes32 key, uint256 off, uint256 len) external view returns (bytes memory);

    function remove(bytes32 key) external;

    function size(bytes32 key) external view returns (uint256);

    function hash(bytes32 key) external view returns (bytes24);

    function upfrontPayment() external view returns (uint256);
}

contract ERC5018ForBlob is IERC5018ForBlob {

    address public owner;
    EthStorageContract public storageContract;

    mapping(bytes32 => bytes32[]) internal keyToChunk;

    constructor() {
        owner = msg.sender;
    }

    function setEthStorageContract(address storageAddress) public {
        require(msg.sender == owner, "must from owner");
        storageContract = EthStorageContract(storageAddress);
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "must from owner");
        owner = newOwner;
    }

    function _countChunks(bytes32 key) internal view returns (uint256) {
        return keyToChunk[key].length;
    }

    function _chunkSize(bytes32 key, uint256 chunkId) internal view returns (uint256, bool) {
        if (chunkId >= _countChunks(key)) {
            return (0, false);
        }
        uint256 size_ = storageContract.size(keyToChunk[key][chunkId]);
        return (size_, true);
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
        (uint256 length,) = _chunkSize(key, chunkId);
        if (length < 1) {
            return (new bytes(0), false);
        }

        bytes memory data = storageContract.get(keyToChunk[key][chunkId], 0, length);
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
        storageContract.remove(keyToChunk[key][chunkId]);
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
            storageContract.remove(keyToChunk[key][chunkId]);
        }
    }

    function _putChunks(
        bytes32 key,
        uint256 value,
        uint256[] memory chunkIds,
        uint256[] memory sizes
    ) internal {
        uint256 length = chunkIds.length;
        require(0 < length && length < 3, "invalid chunk length");

        uint256 cost = storageContract.upfrontPayment();
        require(value >= cost * length, "insufficient balance");

        for (uint8 i = 0; i < length; i++) {
            require(sizes[i] <= 4096 * 31, "invalid blob length");
            _preparePut(key, chunkIds[i]);

            bytes32 chunkKey = keccak256(abi.encode(msg.sender, block.timestamp, chunkIds[i], i));
            storageContract.putBlob{value : cost}(chunkKey, i, sizes[i]);
            if (chunkIds[i] < _countChunks(key)) {
                // replace
                keyToChunk[key][chunkIds[i]] = chunkKey;
            } else {
                // add
                keyToChunk[key].push(chunkKey);
            }
        }
    }



    // interface methods
    function read(bytes memory name) public view override returns (bytes memory, bool) {
        return _get(keccak256(name));
    }

    function size(bytes memory name) public view override returns (uint256, uint256) {
        return _size(keccak256(name));
    }

    function remove(bytes memory name) public override returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name), 0);
    }

    function countChunks(bytes memory name) public view override returns (uint256) {
        return _countChunks(keccak256(name));
    }

    function readChunk(bytes memory name, uint256 chunkId) public view override returns (bytes memory, bool) {
        return _getChunk(keccak256(name), chunkId);
    }

    function chunkSize(bytes memory name, uint256 chunkId) public view override returns (uint256, bool) {
        return _chunkSize(keccak256(name), chunkId);
    }

    function removeChunk(bytes memory name, uint256 chunkId) public override returns (bool) {
        require(msg.sender == owner, "must from owner");
        return _removeChunk(keccak256(name), chunkId);
    }

    function truncate(bytes memory name, uint256 chunkId) public override returns (uint256) {
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
        if (chunkId >= _countChunks(key)) {
            return bytes32(0);
        }
        return storageContract.hash(keyToChunk[key][chunkId]);
    }

    // Chunk-based large storage methods
    function writeChunk(bytes memory name, uint256[] memory chunkIds, uint256[] memory sizes) public override payable {
        require(msg.sender == owner, "must from owner");
        _putChunks(keccak256(name), msg.value, chunkIds, sizes);
        refund();
    }

    function upfrontPayment() external override view returns (uint256) {
        return storageContract.upfrontPayment();
    }
}
