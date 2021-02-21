pragma solidity ^0.5.2;

contract Property {
    uint256 public price = 90000;
    string public location = "Hamburg";
    address public owner;
    address public caller;
    uint256 public last_sent_value;

    //contract constructor, initializes the owner variable with the address
    //of the account that deploys the contract
    constructor() public {
        owner = msg.sender;
    }

    //returns contract balance
    function get_balance() public view returns (uint256) {
        return address(this).balance;
    }

    //the fallback payable  function must be external in solidity 0.5.x
    function() external payable {
        location = "London";
    }

    //msg.sender is the address of the account that calls this function
    //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
    function transfer_balance(address payable recipient_address, uint256 amount)
        public
        returns (bool)
    {
        if (msg.sender == owner) {
            if (amount <= get_balance()) {
                recipient_address.transfer(amount);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function sendEther() public payable {
        last_sent_value = msg.value; //value in wei sent to this contract when calling the function
    }

    //creates a transaction and costs gas
    function setPrice(uint256 _price) public {
        caller = msg.sender;
        price = _price;
    }

    //in solidity 0.5.x memory keyword is mandatory for string arguments
    function setLocation(string memory _location) public returns (bool) {
        caller = msg.sender;
        location = _location;
        return true;
    }
}
