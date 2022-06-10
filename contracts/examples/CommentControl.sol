// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleComment.sol";

contract CommentControl {

    struct CommentInfo {
        address userAddress;
        bool exist;
    }

    struct BlogInfo {
        uint256 commentSize;
        CommentInfo[] commentList;
    }

    mapping(uint256 => BlogInfo) blogInfos;
    mapping(uint256 => address) commentContractList;

    function writeComment(uint256 blogIdx, bytes memory content) public payable {
        address contractAddress = commentContractList[blogIdx];
        if (contractAddress == address(0)) {
            contractAddress = address(new SimpleComment());
            commentContractList[blogIdx] = contractAddress;
        }

        SimpleComment com = SimpleComment(contractAddress);
        com.writeComment(content);

        BlogInfo storage blogInfo = blogInfos[blogIdx];
        blogInfo.commentList.push(CommentInfo(msg.sender, true));
        blogInfo.commentSize++;
    }

    function deleteComment(uint256 blogIdx, uint256 commentId) public {
        address contractAddress = commentContractList[blogIdx];
        require(contractAddress != address(0), "Comment not exist");
        BlogInfo storage blogInfo = blogInfos[blogIdx];
        require(blogInfo.commentSize != 0, "Comment not exist");
        CommentInfo storage info = blogInfo.commentList[commentId];
        require(info.userAddress == msg.sender, "Not Author");

        SimpleComment comment = SimpleComment(contractAddress);
        comment.deleteComment(commentId);

        info.exist = false;
        blogInfo.commentSize--;
    }

    function getComments(uint256 blogIdx)
        public
        view
        returns (
            uint256[] memory ids,
            uint256[] memory timestamps,
            address[] memory users,
            bytes[] memory contents
        )
    {
        address contractAddress = commentContractList[blogIdx];
        if (contractAddress == address(0)) {
            return (new uint256[](0), new uint256[](0), new address[](0), new bytes[](0));
        }

        BlogInfo memory blogInfo = blogInfos[blogIdx];
        uint256 commentSize = blogInfo.commentSize;
        ids = new uint256[](commentSize);
        timestamps = new uint256[](commentSize);
        users = new address[](commentSize);
        contents = new bytes[](commentSize);

        uint256 pt = 0;
        uint256 length = blogInfo.commentList.length;
        for (uint256 i = 0; i < length; i++) {
            CommentInfo memory info = blogInfo.commentList[i];
            if(info.exist){
                SimpleComment comment = SimpleComment(contractAddress);
                (uint256 timestamp,bytes memory content) = comment.getComment(i);
                ids[pt] = i;
                users[pt] = info.userAddress;
                timestamps[pt] = timestamp;
                contents[pt] = content;
                pt++;
            }
        }
        return (ids, timestamps, users, contents);
    }
}
