// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract StartStopUpdateExample {
    address owner;
    bool public paused;

    constructor() {
        owner = msg.sender;
    }

    // deposit into contract account
    function sendMoney() public payable {}

    function setPaused(bool _paused) public {
        require(msg.sender == owner, "You are not the owner");
        paused = _paused;
    }

    function withdrawAllMoney(address payable _to) public {
        require(msg.sender == owner, "You cannot withdraw!");
        require(!paused, "Contract Paused currently");
        _to.transfer(address(this).balance);
    }

    // beneficiary address
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        // solidity internal function
        // _to: address receive the rest of the funds in the smart contract after destroyed 
        selfdestruct(_to);
    }
}
