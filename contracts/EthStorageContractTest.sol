// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LargeStorageManager.sol";

contract EthStorageContractTest is LargeStorageManager(0) {
    // Queue
    mapping(uint256 => bytes32) queue;
    uint256 first = 1;
    uint256 last = 0;

    function enqueue(bytes32 data) public {
        queue[++last] = data;
    }

    function dequeue() public returns (bytes32 data) {
        require(last >= first, "Queue is Empty");
        data = queue[first];
        delete queue[first++];
    }




    // implement
    function putBlob(bytes32 key, uint256 blobIdx, uint256 length) external payable {
        enqueue(key);
    }

    // write real data
    function writeChunk(bytes calldata data) public payable virtual {
        bytes32 key = dequeue();
        return _putChunkFromCalldata(key, 0, data, msg.value);
    }

    function remove(bytes32 key) external {
        _removeChunk(key, 0);
    }

    function get(bytes32 key, uint256 off, uint256 len) external view returns (bytes memory data) {
        (data,) = _getChunk(key, 0);
    }

    function size(bytes32 key) external view returns (uint256 s) {
        (s,) = _chunkSize(key, 0);
    }

    function hash(bytes32 key) external view returns (bytes24) {
        (bytes memory localData,) = _getChunk(key, 0);
        return bytes24(keccak256(localData));
    }

    function upfrontPayment() external view returns (uint256) {
        return 0;
    }
}
