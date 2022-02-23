// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlatDirectory.sol";

contract FlatDirectoryFactory {
    event FlatDirectoryCreated(address);

    function create() public returns (address) {
        FlatDirectory fd = new FlatDirectory();
        fd.changeOwner(msg.sender);
        emit FlatDirectoryCreated(address(fd));
        return address(fd);
    }
}