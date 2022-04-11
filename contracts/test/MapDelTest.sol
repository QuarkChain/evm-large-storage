pragma solidity ^0.8.0;

contract MapDelTest {
    mapping(uint256 => uint256) public Test;

    // empty Test
    // 44115 Store(10,100)
    // 27015 Store(10,101)
    function Store(uint256 key, uint256 value) public {
        Test[key] = value;
    }

    // empty Test
    // 44115 store(2,10)
    // 44618 StoreWithDelOnce(1,9)
    function StoreWithDelOnce(uint256 key, uint256 value) public {
        delete Test[key + 1];
        Test[key] = value;
    }

    // empty Test
    // 44115 store(2,11)
    // 44115 store(3,12)
    // 45121 StoreWithDelTwice(1,9)
    function StoreWithDelTwice(uint256 key, uint256 value) public {
        delete Test[key + 1];
        delete Test[key + 2];
        Test[key] = value;
    }
}
