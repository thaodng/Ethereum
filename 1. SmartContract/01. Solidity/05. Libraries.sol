// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Bank {
    mapping(address => uint256) public accounts;
    using SafeMath for uint256;

    function deposit() public payable {
        require(
            accounts[msg.sender] + msg.value >= accounts[msg.sender],
            "Overflow error"
        );
        accounts[msg.sender] = accounts[msg.sender].add(msg.value);
    }

    function withdraw(uint256 money) public {
        require(money <= accounts[msg.sender]);
        accounts[msg.sender] = accounts[msg.sender].sub(money);
    }
}
