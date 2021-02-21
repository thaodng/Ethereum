// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

// A standard interface for tokens that allows token holders to pay transaction fees by token itself
// Paying transaction fees by tokens

/**
 * @title TRC21 interface
 */
interface ITRC21 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function estimateFee(uint256 value) external view returns (uint256);
    function issuer() external view returns (address);
    function decimals() external view returns (uint8);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}
