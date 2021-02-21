// SPDX-License-Identifier: GPL-3.0

/* Address -> (totalBalance, numPayments, payments) ->
 * '0x123' -> (0.5 ether, 5, 0 -> (100 ether, '10/02/2021'))
 *                           1 -> (200 ether, '11/02/2021'))
 */
pragma solidity >=0.7.0 <0.8.0;

contract MappingsStructExample {
    struct Payment {
        uint256 amount;
        uint256 timestamp;
    }

    struct Balance {
        uint256 totalBalance;
        uint256 numPayments;
        mapping(uint256 => Payment) payments;
    }

    mapping(address => Balance) public balanceReceived;

    // tracking that 'sender' has deposited money into the 'contract'
    function sendMoney() public payable {
        balanceReceived[msg.sender].totalBalance += msg.value;
        Payment memory payment = Payment(msg.value, block.timestamp);
        balanceReceived[msg.sender].payments[
            balanceReceived[msg.sender].numPayments
        ] = payment;
        balanceReceived[msg.sender].numPayments++;
    }

    // transfer all money of 'sender' to '_to'
    function withdrawAllMoney(address payable _to) public {
        uint256 balanceToSend = balanceReceived[msg.sender].totalBalance;
        balanceReceived[msg.sender].totalBalance = 0;
        _to.transfer(balanceToSend);
    }

    // transfer 'amount' deposited of 'sender' to '_to'
    function withdrawMoney(address payable _to, uint256 _amount) public {
        require(
            _amount <= balanceReceived[msg.sender].totalBalance,
            "not enough funds"
        );
        balanceReceived[msg.sender].totalBalance -= _amount;
        _to.transfer(_amount);
    }

    // get balance of address
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
