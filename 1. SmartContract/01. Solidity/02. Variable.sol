// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract VariableExamples {
    bool public switchedOn = true;
    address public owner = msg.sender;
    uint8 public number = 8;
    bytes32 public awesome1 = "Solidity is awesome!";
    string public awesome2 = "Solidity is awesome!";
}

contract SampleContract {
    uint8[3] nums = [10, 20, 30];

    function getNums() public returns (uint8[3] memory) {
        nums[0] = 11;
        nums[1] = 22;
        nums[2] = 33;
        return nums;
    }

    function getLength() public view returns (uint256) {
        return nums.length;
    }
}

contract Score {
    uint24[] score;

    function addScore(uint24 s) public returns (uint24[] memory) {
        score.push(s);
        return score;
    }

    function getLength() public view returns (uint256) {
        return score.length;
    }

    function clearArray() public returns (uint24[] memory) {
        delete score;
        return score;
    }
}

contract ChangeArrayValue {
    uint256[20] public arr;

    function startChange() public {
        firstChange(arr);
        secondChange(arr);
    }

    // 'storage' point to the same memory location -> change the state
    function firstChange(uint256[20] storage x) internal {
        x[0] = 4;
    }

    // 'memory' create a temporary memory location -> not change the state -> ide automatically restrict to 'pure'
    function secondChange(uint256[20] memory x) internal pure {
        x[0] = 3;
    }
}
