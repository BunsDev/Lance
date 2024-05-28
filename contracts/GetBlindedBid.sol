// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract GetBlindedBid {
    uint256[] array = [0,1,2,3,4,5,6,7,8];
    
    function getBlindedBid(uint value, bytes32 secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(value,  secret));
    }

    function subract(int value1, int value2) public pure returns (int) {
        return value1 - value2;
    }

    function division(int value1, int value2) public pure returns (int) {
        return value1/value2;
    }

    function deleteArr() public {
    uint256 index = 5;
    require(index < array.length);
    array[index] = array[array.length-1];
    array.pop();
    }

    function getArray() public view returns (uint256[] memory) {
        return array;
    }

}