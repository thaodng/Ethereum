pragma solidity ^0.6.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./Allowance.sol";

contract SharedWallet is Allowance {
    event MoneySent(address indexed _beneficiary, uint256 _amount);
    event MoneyReceived(address indexed _from, uint256 _amount);

    // maybe another function called withdrawMoney for allowance person or for a third party.
    function withdrawMoney(address payable _to, uint256 _amount) public ownerOrAllowed(_amount) {
        require(
            _amount <= address(this).balance,
            "Contract doesn't own enough money"
        );

        if (!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }

    // override renounceOwnership -> make thois doesn's exists in our contract
    function renounceOwnership() public onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}
