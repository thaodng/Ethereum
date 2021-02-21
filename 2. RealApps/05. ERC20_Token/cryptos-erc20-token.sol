pragma solidity ^0.4.24;

/* Million of dollars have been lost because users sent tokens to contract address instead of externally own account addresses */
/* Wallet behind the scene send the transaction to the contract address and aumatically call transfer function thanks to ERC20 standard */

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner) public view returns (uint256 balance);

    function transfer(address to, uint256 tokens) public returns (bool success);

    //function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    //function approve(address spender, uint tokens) public returns (bool success);
    //function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint256 public decimals = 0; // many tokens have a value of 18 decimal

    uint256 public supply; // how many tokens will this contract create
    address public founder;

    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor() public {
        supply = 300000000000000000000000;
        founder = msg.sender;
        balances[founder] = supply;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    //transfer from the owner balance to another address
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0);

        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}
