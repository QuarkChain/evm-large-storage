// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";
import "./SimpleComment.sol";

contract SimpleBlog is SimpleFlatDirectory {
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct Blog {
        bytes title;
        uint256 timestamp; // 0 means deleted
    }

    struct Comment {
        address owner;
        uint256 timestamp;
    }

    struct CommentsInfo {
        address contractAddress;
        uint256 commentSize;
        Comment[] commentList;
    }

    Blog[] public blogs;
    uint256 public blogLength;

    mapping(uint256 => CommentsInfo) commentsList;

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
        info.contractAddress = address(new SimpleComment());
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

        uint256 commentId = info.commentList.length;
        SimpleComment com = SimpleComment(contractAddress);
        com.writeComment(commentId, content);
        info.commentList.push(Comment(msg.sender, block.timestamp));
        info.commentSize++;
    }

    function deleteComment(uint256 idx, uint256 commentId) public {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        require(contractAddress != address(0), "blog not exist");

        Comment storage com = info.commentList[commentId];
        require(com.owner == msg.sender, "Only owner can delete");

        SimpleComment comment = SimpleComment(contractAddress);
        comment.deleteComment(commentId);
        com.timestamp = 0;
        com.owner = address(0);
        info.commentSize--;
    }

    function getComments(uint256 idx)
        public
        view
        returns (
            uint256[] memory ids,
            uint256[] memory timestamps,
            address[] memory users,
            bytes[] memory contents
        )
    {
        CommentsInfo storage info = commentsList[idx];
        address contractAddress = info.contractAddress;
        if (contractAddress == address(0)) {
            return (new uint256[](0), new uint256[](0), new address[](0), new bytes[](0));
        }

        uint256 commentSize = info.commentSize;
        ids = new uint256[](commentSize);
        timestamps = new uint256[](commentSize);
        users = new address[](commentSize);
        contents = new bytes[](commentSize);

        uint256 pt = 0;
        uint256 length = info.commentList.length;
        for (uint256 i = 0; i < length; i++) {
            Comment memory com = info.commentList[i];
            if(com.timestamp != 0){
                SimpleComment comment = SimpleComment(contractAddress);
                bytes memory content = comment.getComment(i);
                ids[pt] = i;
                users[pt] = com.owner;
                timestamps[pt] = com.timestamp;
                contents[pt] = content;
                pt++;
            }
        }
        return (ids, timestamps, users, contents);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
}
