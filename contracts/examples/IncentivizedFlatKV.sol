// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FlatDirectory.sol";
contract IncentivizedFlatKV is FlatDirectory{
    address public operator;
    constructor(uint8 slotLimit) FlatDirectory(slotLimit) {}

     modifier onlyOperatorOrOwner(){
        require(operator == msg.sender || owner == msg.sender,"only owner or opetator");
        _;
    }

    function changeOperator(address _operator) public onlyOperatorOrOwner virtual {
        operator = _operator;
    }

    function setDefault(bytes memory _defaultFile) public onlyOperatorOrOwner override virtual{
        defaultFile = _defaultFile;
    }

    function write(bytes memory name, bytes memory data)
        public
        payable
        override
        onlyOperatorOrOwner
    {
        return _putChunk(keccak256(name), 0, data, msg.value);
    }

    function remove(bytes memory name) public override onlyOperatorOrOwner returns (uint256) {
        require(msg.sender == owner, "must from owner");
        return _remove(keccak256(name));
    }

    function writeChunk(
        bytes memory name,
        uint256 chunkId,
        bytes memory data
    ) public payable override onlyOperatorOrOwner{
        return _putChunk(keccak256(name), chunkId, data, msg.value);
    }

    function removeChunk(bytes memory name, uint256 chunkId)
        public
        override
        onlyOperatorOrOwner
        returns (bool)
    {
        return _removeChunk(keccak256(name), chunkId);
    }

}