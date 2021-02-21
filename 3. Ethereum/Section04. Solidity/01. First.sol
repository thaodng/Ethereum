// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract Storage {
    uint256 public number;    
    /**
     * @dev Store value in variable
     * @param _number value to store
     */
    function store(uint256 _number) public {
        number = _number;
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    // *****************************
    bool public myBool;
    
    function setMyBool(bool _myBool) public {
      myBool = _myBool;
    }

    // *****************************
    address public myAddress;
    function setAddress(address _address) public {
      myAddress = _address;
    }
    // return balance in wei   
    function getBalanceOfAddress() public view return (uint) {
      return myAddress.balance;
    }

    // *****************************
    string public myString = "Hello world";
    // reference variable stored on memory is cheaper than on storage
    function setMyString(string memory _myString) public {
      myString = _myString;
    }

    // *****************************
       
}