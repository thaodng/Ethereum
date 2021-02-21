// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Messenger {
    address owner;
    string[] messages;

    constructor() {
        owner = msg.sender;
    }

    function add(string memory newMessage) public {
        require(msg.sender == owner);
        messages.push(newMessage);
    }

    function count() public view returns (uint256) {
        return messages.length;
    }

    function getMessages(uint256 index) public view returns (string memory) {
        return messages[index];
    }
}


contract MessageContract {
    string private message = "Hello World";

    function getMessage() public view returns (string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}