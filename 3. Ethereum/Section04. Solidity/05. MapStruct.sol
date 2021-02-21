// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract MappingsStructExample {
    
    // mapping(address => Balance) public balanceReceived;
    mapping(address => uint256) public balanceReceived;

    // tracking that 'sender' has deposited money into the 'contract'
    function sendMoney() public payable {
        balanceReceived[msg.sender] += msg.value;
    }

    // transfer all money of 'sender' to '_to'
    function withdrawAllMoney(address payable _to) public {
        uint256 balanceToSend = balanceReceived[msg.sender];
        balanceReceived[msg.sender] = 0;
        _to.transfer(balanceToSend);
    }

    // transfer 'amount' deposited of 'sender' to '_to'
    function withdrawMoney(address payable _to, uint256 _amount) public {
        // if satisfy condition thhen do sth <-> require
        require(_amount <= balanceReceived[msg.sender], "not enough funds");
        balanceReceived[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

    // get balance of address
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
