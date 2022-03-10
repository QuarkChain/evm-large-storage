// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleFlatDirectory.sol";

contract SimpleBlog is SimpleFlatDirectory {
    struct Blog {
        bytes title;
        uint256 timestamp; // 0 means deleted
    }

    Blog[] public blogs;
    uint256 public blogLength;

    function writeBlog(bytes memory title, bytes memory content)
        public
        payable
    {
        uint256 idx = blogs.length;
        blogs.push(Blog(title, block.timestamp)); // solhint-disable-line not-rely-on-time
        blogLength++;
        write(abi.encodePacked(idx), content);
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
}
