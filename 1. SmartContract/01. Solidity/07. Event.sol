// SPDX-License-Identifier: GPL-3.0

/* It should be 0x followed by a 64-character hexadecimal string. 
 * E.g. 0x7465737400000000000000000000000000000000000000000000000000000000 
 * (corresponding to the ASCII string "test").
 */

pragma solidity >=0.7.0 <0.8.0;

contract SmartExchange {
    event Deposit(address from, bytes32 to, uint256 indexed value);
    event Transfer(bytes32 from, address to, uint256 indexed value);

    function deposit(bytes32 to) public payable {
        emit Deposit(msg.sender, to, msg.value);
    }

    function transfer(
        bytes32 from,
        address payable to,
        uint256 value
    ) public payable {
        to.transfer(value);
        emit Transfer(from, to, value);
    }
}
