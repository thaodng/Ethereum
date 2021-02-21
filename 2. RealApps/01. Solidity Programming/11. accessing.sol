pragma solidity ^0.5.2;

contract Property {
    //state variables
    uint256 public price = 90000;
    string public location = "Hamburg";
    address public owner;

    //contract constructor
    constructor() public {
        owner = msg.sender;
    }

    //returns the contract balance in wei
    function get_balance() public view returns (uint256) {
        return address(this).balance;
    }

    //fallback payable function. It's mandatory to be external in solidity 0.5.x
    //this function is automatically called when sending ether directly to the contract address
    //there could be only one fallback payable function, it has no arguments and no return is allowed
    function() external payable {
        location = "London";
    }

    //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
    function transfer_balance(address payable recipient_address, uint256 amount)
        public
        returns (bool)
    {
        if (msg.sender == owner) {
            if (amount <= get_balance()) {
                //transfer the amount received as argument to the recipient_address
                recipient_address.transfer(amount);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    //payable function, ether are sent to the contract when calling this functions
    //there could be more payable functions
    function sendEther() public payable {
        price = 600;
    }

    //setter function, creates a transaction and costs gas
    function setPrice(uint256 _price) public {
        price = _price;
    }

    //memory keyword for variables of type string is mandatory in solidity 0.5.x
    function setLocation(string memory _location) public {
        location = _location;
    }

    //memory keyword for variables of type string is mandatory in solidity 0.5.x
    function getLocation() public view returns (string memory) {
        return location;
    }
}
