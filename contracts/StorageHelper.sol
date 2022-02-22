// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Memory.sol";
import "./StorageSlotFactory.sol";

library StorageHelper {
    // StorageSlotSelfDestructable compiled via solc 0.8.7 optimized 200
    bytes internal constant STORAGE_SLOT_CODE =
        hex"6080604052348015600f57600080fd5b506004361060325760003560e01c80632b68b9c61460375780638da5cb5b14603f575b600080fd5b603d6081565b005b60657f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161460ed5760405162461bcd60e51b815260206004820152600e60248201526d3737ba10333937b69037bbb732b960911b604482015260640160405180910390fd5b33fffea2646970667358221220fc66c9afb7cb2f6209ae28167cf26c6c06f86a82cbe3c56de99027979389a1be64736f6c63430008070033";
    uint256 internal constant ADDR_OFF0 = 67;
    uint256 internal constant ADDR_OFF1 = 140;

    // StorageSlotFactoryFromInput compiled via solc 0.8.7 optimized 200 + STORAGE_SLOT_CODE
    bytes internal constant FACTORY_CODE =
        hex"60806040526040516101113803806101118339810160408190526100229161002b565b80518060208301f35b6000602080838503121561003e57600080fd5b82516001600160401b038082111561005557600080fd5b818501915085601f83011261006957600080fd5b81518181111561007b5761007b6100fa565b604051601f8201601f19908116603f011681019083821181831017156100a3576100a36100fa565b8160405282815288868487010111156100bb57600080fd5b600093505b828410156100dd57848401860151818501870152928501926100c0565b828411156100ee5760008684830101525b98975050505050505050565b634e487b7160e01b600052604160045260246000fdfe000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000006080604052348015600f57600080fd5b506004361060325760003560e01c80632b68b9c61460375780638da5cb5b14603f575b600080fd5b603d6081565b005b60657f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f35b336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161460ed5760405162461bcd60e51b815260206004820152600e60248201526d3737ba10333937b69037bbb732b960911b604482015260640160405180910390fd5b33fffea2646970667358221220fc66c9afb7cb2f6209ae28167cf26c6c06f86a82cbe3c56de99027979389a1be64736f6c63430008070033";
    uint256 internal constant FACTORY_SIZE_OFF = 305;
    uint256 internal constant FACTORY_ADDR_OFF0 = 305 + 32 + ADDR_OFF0;
    uint256 internal constant FACTORY_ADDR_OFF1 = 305 + 32 + ADDR_OFF1;

    function putRaw(bytes memory data, uint256 value) internal returns (address) {
        // create the new contract code with the data
        bytes memory bytecode = STORAGE_SLOT_CODE;
        uint256 bytecodeLen = bytecode.length;
        uint256 newSize = bytecode.length + data.length;
        assembly {
            // in-place resize of bytecode bytes
            // note that this must be done when bytecode is the last allocated object by solidity.
            mstore(bytecode, newSize)
            // notify solidity about the memory size increase, must be 32-bytes aligned
            mstore(
                0x40,
                add(bytecode, and(add(add(newSize, 0x20), 0x1f), not(0x1f)))
            )
        }
        // append data to self-destruct byte code
        Memory.copy(
            Memory.dataPtr(data),
            Memory.dataPtr(bytecode) + bytecodeLen,
            data.length
        );
        {
            // revise the owner to the contract (so that it is destructable)
            uint256 off = ADDR_OFF0 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
            off = ADDR_OFF1 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
        }

        StorageSlotFactoryFromInput c = new StorageSlotFactoryFromInput{value: value}(
            bytecode
        );
        return address(c);
    }

    function putRaw2(bytes32 key, bytes memory data, uint256 value) internal returns (address) {
        // create the new contract code with the data
        bytes memory bytecode = FACTORY_CODE;
        uint256 bytecodeLen = bytecode.length;
        uint256 newSize = bytecode.length + data.length;
        assembly {
            // in-place resize of bytecode bytes
            // note that this must be done when bytecode is the last allocated object by solidity.
            mstore(bytecode, newSize)
            // notify solidity about the memory size increase, must be 32-bytes aligned
            mstore(
                0x40,
                add(bytecode, and(add(add(newSize, 0x20), 0x1f), not(0x1f)))
            )
        }
        // append data to self-destruct byte code
        Memory.copy(
            Memory.dataPtr(data),
            Memory.dataPtr(bytecode) + bytecodeLen,
            data.length
        );
        {
            // revise the size of calldata
            uint256 calldataSize = STORAGE_SLOT_CODE.length + data.length;
            uint256 off = FACTORY_SIZE_OFF + 0x20;
            assembly {
                mstore(add(bytecode, off), calldataSize)
            }
        }
        {
            // revise the owner to the contract (so that it is destructable)
            uint256 off = FACTORY_ADDR_OFF0 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
            off = FACTORY_ADDR_OFF1 + 0x20;
            assembly {
                mstore(add(bytecode, off), address())
            }
        }

        address addr;
        assembly {
            addr := create2(
                value,
                add(bytecode, 0x20), // data offset
                mload(bytecode), // size
                key
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }
}