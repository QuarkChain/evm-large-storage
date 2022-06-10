// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";

contract SimpleComment is SimpleFlatDirectory {
    struct Comment {
        uint256 timestamp;
    }

    Comment[] comments;
    uint256 public commentLength;

    function writeComment(bytes memory content) public payable returns(uint256){
        uint256 id = comments.length;
        comments.push(Comment(block.timestamp));
        write(abi.encodePacked(id), content);
        commentLength++;
        return id;
    }

    function deleteComment(uint256 id) public {
        Comment storage com = comments[id];
        com.timestamp = 0;
        commentLength--;
        remove(abi.encodePacked(id));
    }

    function getComment(uint256 idx)
        public
        view
        returns (
            uint256 timestamp,
            bytes memory content
        )
    {
        Comment memory com = comments[idx];
        content = files(abi.encodePacked(idx));
        return (com.timestamp, content);
    }
}

