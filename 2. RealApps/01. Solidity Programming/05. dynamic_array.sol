pragma solidity ^0.4.24;

contract Property {
    string public location = "London";
    uint256[] public prices;

    function add_price(uint256 _price) public {
        prices.push(_price);
    }

    function get_length() public view returns (uint256) {
        return prices.length;
    }

    function get_element(uint256 index) public view returns (uint256) {
        if (index < prices.length) {
            return prices[index];
        }
    }

    function delete_element(uint256 index) public returns (bool) {
        if (index >= prices.length) return false;

        for (uint256 i = index; i < prices.length - 1; i++) {
            prices[i] = prices[i + 1];
        }

        prices.length--;
        return true;
    }

    function f() public {
        uint256[] storage myArray = prices; //this is recommended
    }
}
