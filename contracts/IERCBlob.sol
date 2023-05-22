// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCBlob {

    function writeChunkBlob(
        bytes memory name,
        uint256 chunkId,
        bytes32 chunkHash,
        uint256[] memory blobLengths
    ) external payable;

    function upfrontPayment() external view returns (uint256);
}
