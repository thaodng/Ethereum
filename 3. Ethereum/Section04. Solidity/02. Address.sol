// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract SendMoney {
  
  uint public balanceReceived;

  // transfer ether from external account to contract account
  function receiveMoney() public payable {
    // lưu trữ lại số tiền đã gửi vào contract - stored the amount of deposited in 'balanceReceived' variable
    // balanReceived === address(this).balance
    balanceReceived += msg.value; // amount in wei that was sent to this account
  }

  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  // getting money out of the contract - so we don't need payable
  function withdrawMoney() public {
    address payable to = msg.sender;
    to.transfer(this.getBalance()); // amount in wei we want to transfer money to 'to' address
  }

  function withdrawMoneyTo(address payable to, uint amount) public {
    to.transfer(amount); // amount in wei we want to transfer money to 'to' address
  }
}