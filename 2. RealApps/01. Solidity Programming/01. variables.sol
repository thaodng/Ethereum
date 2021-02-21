pragma solidity ^0.7.4;

contract Property {
    // these 'state' variables cost gas
    string public location = "Paris";
    int256 public price; //by default is initialized with 0
    int256[] public y;

    // location = "London"; //this is not permitted in solidity

    // setter function, sets a state variable
    // in solidity 0.5.x memory keyword is mandatory for argument function reference type
    function setProperty(string memory _location) public {
        //_location is local and saved in memory
        location = _location;

        int256 a; //local variable, saved on the stack

        // 'x' point at the same 'memory location' of 'y'
        int256[] storage x = y; //dynamic array, this is saved in storage
    }
}
