// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";
import "./FlatDirectory.sol";
import "./SimpleComment.sol";

contract SimpleBlog is SimpleFlatDirectory {
    struct Blog {
        bytes title;
        uint256 timestamp; // 0 means deleted
    }

    struct CommentsInfo {
        address contractAddress;
        uint256 commentSize;
    }

    Blog[] public blogs;
    uint256 public blogLength;

    mapping(uint256 => CommentsInfo) public commentsList;

    address public assets;

    constructor() SimpleFlatDirectory(0) {
        FlatDirectory flat = new FlatDirectory(0);
        flat.changeOwner(msg.sender);
        assets = address(flat);
    }

    function writeBlog(bytes memory title, bytes memory content)
        public
        payable
    {
        uint256 idx = blogs.length;
        blogs.push(Blog(title, block.timestamp)); // solhint-disable-line not-rely-on-time
        blogLength++;
        write(abi.encodePacked(idx), content);

        // pre comment
        CommentsInfo storage info = commentsList[idx];
        SimpleComment comment = new SimpleComment();
        info.contractAddress = address(comment);
    }

    function editBlog(
        uint256 idx,
        bytes memory newTitle,
        bytes memory newContent
    ) public payable {
        Blog storage blog = blogs[idx];
        require(blog.timestamp != 0, "non-existent");
        blog.title = newTitle;
        blog.timestamp = block.timestamp; // solhint-disable-line not-rely-on-time
        write(abi.encodePacked(idx), newContent);
    }

    function deleteBlog(uint256 idx) public {
        blogs[idx].timestamp = 0;
        blogLength--;
        remove(abi.encodePacked(idx));
    }

    function listBlogs()
        public
        view
        returns (
            bytes[] memory titles,
            uint256[] memory timestamps,
            uint256[] memory idxList
        )
    {
        // TODO: pagination
        titles = new bytes[](blogLength);
        timestamps = new uint256[](blogLength);
        idxList = new uint256[](blogLength);
        uint256 pt = 0;

        for (uint256 i = 0; i < blogs.length; i++) {
            Blog memory b = blogs[i];
            if (b.timestamp != 0) {
                titles[pt] = b.title;
                timestamps[pt] = b.timestamp;
                idxList[pt] = i;
                pt++;
            }
        }
        return (titles, timestamps, idxList);
    }

    function getBlog(uint256 idx)
        public
        view
        returns (
            bytes memory title,
            uint256 timestamp,
            bytes memory content
        )
    {
        Blog memory blog = blogs[idx];
        content = files(abi.encodePacked(idx));
        return (blog.title, blog.timestamp, content);
    }

    function nextPost(uint256 idx) public view returns (uint256, bool) {
        while (idx < blogs.length - 1) {
            if (blogs[++idx].timestamp != 0) return (idx, true);
        }
        return (0, false);
    }

    function prevPost(uint256 idx) public view returns (uint256, bool) {
        while (idx != 0) {
            if (blogs[--idx].timestamp != 0) return (idx, true);
        }
        return (0, false);
    }


    function writeComment(uint256 idx, bytes memory content) public payable {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        require(contractAddress != address(0), "blog not exist");

        SimpleComment com = SimpleComment(contractAddress);
        com.writeComment(info.commentSize, content);
        com.writeOwner(info.commentSize, msg.sender);
        com.writeTimestamp(info.commentSize, block.timestamp);
        info.commentSize++;
    }

    function deleteComment(uint256 idx, uint256 commentId) public {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        require(contractAddress != address(0), "blog not exist");

        SimpleComment comment = SimpleComment(contractAddress);
        address owner = comment.getOwner(commentId);
        require(owner == msg.sender, "Only owner can delete");

        comment.deleteComment(commentId, info.commentSize);
        info.commentSize--;
    }

    function getComments(uint256 idx)
        public
        view
        returns (
            address[] memory users,
            bytes[] memory timestamps,
            bytes[] memory contents
        )
    {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        if (contractAddress == address(0)) {
            return (new address[](0), new bytes[](0), new bytes[](0));
        }

        uint256 commentSize = info.commentSize;
        users = new address[](commentSize);
        timestamps = new bytes[](commentSize);
        contents = new bytes[](commentSize);

        SimpleComment comment = SimpleComment(contractAddress);
        for (uint256 i = 0; i < commentSize; i++) {
            timestamps[i] = comment.getTimestamp(i);
            users[i] = comment.getOwner(i);
            contents[i] = comment.getComment(i);
        }
        return (users, timestamps, contents);
    }
}
