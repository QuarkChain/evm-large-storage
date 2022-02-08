// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageSlotSelfDestructable {
    address immutable public owner;
    
    constructor () {
        owner = msg.sender;
    }

    function destruct() public {
        require(msg.sender == owner, "not from owner");
        selfdestruct(payable(msg.sender));
    }
}