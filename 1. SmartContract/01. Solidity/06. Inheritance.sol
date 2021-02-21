// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

abstract contract Animal {
    string public breed;
    uint256 public age;
    uint256 public weight;

    constructor() {
        age = 1;
        weight = 1;
    }

    function sleep() public pure returns (string memory) {
        return "Zzzzz...";
    }

    function eat() public pure returns (string memory) {
        return "Nom nom..";
    }

    function talk() public pure virtual returns (string memory);
}

contract Cat is Animal {
    constructor() {
        breed = "Persian";
        age = 3;
        weight = 5;
    }

    function talk() public pure override returns (string memory) {
        return "miaow";
    }
}

contract Dog is Animal {
    constructor() {
        breed = "Labrador";
        age = 5;
        weight = 3;
    }

    function talk() public pure override returns (string memory) {
        return "bark bark";
    }
}
