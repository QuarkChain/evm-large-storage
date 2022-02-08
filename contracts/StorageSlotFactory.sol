// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Memory.sol";

// Create a storage slot by appending data to the end
contract StorageSlotFromContract {
    constructor(address contractAddr, bytes memory data) payable {
        uint256 codeSize;
        assembly {
            // retrieve the size of the code, this needs assembly
            codeSize := extcodesize(contractAddr)
        }

        uint256 totalSize = codeSize + data.length + 32;
        bytes memory deployCode = new bytes(totalSize);

        // Copy contract code
        assembly {
            // actually retrieve the code, this needs assembly
            extcodecopy(contractAddr, add(deployCode, 0x20), 0, codeSize)
        }

        // Copy data
        uint256 off = Memory.dataPtr(deployCode) + codeSize;
        Memory.copy(Memory.dataPtr(data), off, data.length);

        off += data.length;
        uint256 len = data.length;
        // Set data size
        assembly {
            mstore(off, len)
        }

        // Return the contract manually
        assembly {
            return(add(deployCode, 0x20), totalSize)
        }
    }
}

// Create a storage slot
contract StorageSlotFactoryFromInput {
    constructor(bytes memory codeAndData) payable {
        uint256 size = codeAndData.length;
        // Return the contract manually
        assembly {
            return(add(codeAndData, 0x20), size)
        }
    }
}
