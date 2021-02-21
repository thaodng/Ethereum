pragma solidity ^0.7.4;

contract Autos {
    //introducing a new variable type
    struct Car {
        string brand;
        uint256 built_year;
        uint256 value;
    }

    enum State {Running, Stopped, Inactive} //!no semicolon here
    State public status = State.Running;

    //state varible of type Car
    Car public private_car;

    //mapping, keys are of type addresses and values of type car
    mapping(address => Car) public cars;

    //initialize the struct state variable
    //in solidity 0.5.x memory keyword is mandatory for string arguments
    //in solidity 0.5.x the visibility specifier (public, private etc) is mandatory.
    constructor(
        string memory _brand,
        uint256 _built_year,
        uint256 _value
    ) {
        private_car.brand = _brand;
        private_car.built_year = _built_year;
        private_car.value = _value;
        cars[msg.sender] = private_car;
    }

    //modifies the struct state variables
    //in solidity 0.5.x memory keyword is mandatory for string arguments
    function modify_car(
        string memory _brand,
        uint256 _built_year,
        uint256 _value
    ) public {
        //this is an in memory variable, is not saved in storage
        Car memory newCar = Car({brand: _brand, built_year: _built_year, value: _value});
        private_car = newCar;
    }
}
