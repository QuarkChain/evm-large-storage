// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlatDirectory.sol";

contract IncentivizedFlatDirectory is FlatDirectory {
    address public operator;

    uint256 public immutable perChunkSize;
    uint256 public immutable codeStakingPerChunk;

    constructor(
        uint8 _slotLimit,
        uint256 _perChunkSize,
        uint256 _codeStakingPerChunk
    ) payable FlatDirectory(_slotLimit) {
        perChunkSize = _perChunkSize;
        codeStakingPerChunk = _codeStakingPerChunk;
    }

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
                    perChunkSize,
                    codeStakingPerChunk
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
                    perChunkSize,
                    codeStakingPerChunk
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

    function calculateValueForData(uint256 datalen) public view returns (uint256) {
        return
            StorageHelper.calculateValueForData(
                datalen,
                perChunkSize,
                codeStakingPerChunk
            );
    }

    function storageSlotCodeLength() public pure returns (uint256) {
        return StorageHelper.storageSlotCodeLength();
    }
}
