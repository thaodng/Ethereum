// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract owned {
    constructor() {
        owner = msg.sender;
    }

    address payable owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract mortal is owned {
    function close() public onlyOwner {
        selfdestruct(owner);
    }
}
