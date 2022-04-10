// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlatDirectory.sol";

contract IncentivizedFlatDirectory is FlatDirectory {
    address public operator;

    uint256 public constant PER_CHUNK_SIZE = 24 * 1024;
    uint256 public constant CODE_STAKING_PER_CHUNK = 10 ** 18;

    constructor(
        uint8 _slotLimit
    ) payable FlatDirectory(_slotLimit) {}

    modifier onlyOperatorOrOwner() {
        require(
            operator == msg.sender || owner == msg.sender,
            "must from owner or operator"
        );
        _;
    }

    function changeOperator(address _operator)
        public
        virtual
        onlyOperatorOrOwner
    {
        operator = _operator;
    }

    function setDefault(bytes memory _defaultFile)
        public
        virtual
        override
        onlyOperatorOrOwner
    {
        defaultFile = _defaultFile;
    }

    function write(bytes memory name, bytes memory data)
        public
        payable
        override
        onlyOperatorOrOwner
    {
        return
            _putChunk(
                keccak256(name),
                0,
                data,
                StorageHelper.calculateValueForData(
                    data.length,
                    PER_CHUNK_SIZE,
                    CODE_STAKING_PER_CHUNK
                )
            );
    }

    function remove(bytes memory name)
        public
        override
        onlyOperatorOrOwner
        returns (uint256)
    {
        return _remove(keccak256(name));
    }

    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes memory data
    ) public payable override onlyOperatorOrOwner {
        return
            _putChunk(
                keccak256(name),
                chunkId,
                data,
                StorageHelper.calculateValueForData(
                    data.length,
                    PER_CHUNK_SIZE,
                    CODE_STAKING_PER_CHUNK
                )
            );
    }

    function removeChunk(bytes memory name, uint256 chunkId)
        public
        override
        onlyOperatorOrOwner
        returns (bool)
    {
        return _removeChunk(keccak256(name), chunkId);
    }

    function calculateValueForData(uint256 datalen) public pure returns (uint256) {
        return
            StorageHelper.calculateValueForData(
                datalen,
                PER_CHUNK_SIZE,
                CODE_STAKING_PER_CHUNK
            );
    }

    function storageSlotCodeLength() public pure returns (uint256) {
        return StorageHelper.storageSlotCodeLength();
    }
}