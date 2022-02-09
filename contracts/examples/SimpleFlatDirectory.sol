// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../StorageManager.sol";

contract SimpleFlatDirectory is StorageManager {
    bytes public defaultFile = "";
    address public immutable owner;
    bytes32 public resolveMode = "auto";

    constructor() {
        owner = msg.sender;
    }

    fallback() external {
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

    function remove(bytes32 node) public returns (bool) {
        require(msg.sender == owner, "must from owner");
        return _remove(node);
    }

    function destruct() public {
        require(msg.sender == owner, "must from owner");
        selfdestruct(payable(owner));
    }
}
