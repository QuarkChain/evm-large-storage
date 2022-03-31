// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../StorageManager.sol";

contract SimpleFlatDirectory is StorageManager {
    bytes public defaultFile = "";
    address public immutable owner;

    constructor(uint8 slotLimit) StorageManager(slotLimit) {
        owner = msg.sender;
    }

    function resolveMode() external pure virtual returns (bytes32) {
        return "auto";
    }

    fallback() external virtual {
        // looks like return data does not work, use assembly
        bytes memory data = files(defaultFile);
        bytes memory returnData = abi.encode(data);

        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }

    function setDefault(bytes memory _defaultFile) public {
        require(msg.sender == owner, "must from owner");
        defaultFile = _defaultFile;
    }

    function bytesToBytes32(bytes memory data) internal pure returns (bytes32) {
        bytes32 b32;
        assembly {
            b32 := mload(add(data, 0x20))
        }
        return b32;
    }

    function files(bytes memory filename) public view returns (bytes memory) {
        bytes32 b32 = bytesToBytes32(filename);
        (bytes memory data, ) = _get(b32);
        return data;
    }

    function write(bytes memory filename, bytes memory data) public payable {
        require(msg.sender == owner, "must from owner");
        bytes32 b32 = bytesToBytes32(filename);
        _put(b32, data, msg.value);
    }

    function remove(bytes memory filename) public returns (bool) {
        require(msg.sender == owner, "must from owner");
        bytes32 b32 = bytesToBytes32(filename);
        return _remove(b32);
    }

    function refund() public {
        require(msg.sender == owner, "must from owner");
        payable(owner).transfer(address(this).balance);
    }

    function destruct() public {
        require(msg.sender == owner, "must from owner");
        selfdestruct(payable(owner));
    }
}
