// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";

contract SimpleComment is SimpleFlatDirectory {

    function writeComment(uint256 id, bytes memory content) public payable {
        write(abi.encodePacked(id), content);
    }

    function deleteComment(uint256 id) public {
        remove(abi.encodePacked(id));
    }

    function getComment(uint256 idx)
        public
        view
        returns (
            bytes memory content
        )
    {
        content = files(abi.encodePacked(idx));
        return content;
    }
}

