// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract SimpleMappingExample {
    // default value was 'false'
    mapping(uint256 => bool) public myMapping;
    mapping(address => bool) public myAddressMapping;

    function setValue(uint256 _index) public {
        myMapping[_index] = true;
    }

    function setMyAddressToTrue() public {
        myAddressMapping[msg.sender] = true;
    }
}
