// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../StorageManager.sol";

contract SimpleFlatDirectory is StorageManager {
    bytes public defaultFile = "";

    event INFO(uint256);

    fallback() external {
        // looks like return data does not work, use assembly
        bytes memory data = files(defaultFile);
        bytes memory returnData = abi.encode(data);
        emit INFO(returnData.length);

        assembly {
            return(add(returnData, 0x20), mload(returnData))
        }
    }

    function setDefault(bytes memory _defaultFile) public {
        defaultFile = _defaultFile;
    }

    function bytesToBytes32(bytes memory data) public pure returns (bytes32) {
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

    function write(bytes memory filename, bytes memory data) payable public {
        bytes32 b32 = bytesToBytes32(filename);
        _put(b32, data, msg.value);
    }
}