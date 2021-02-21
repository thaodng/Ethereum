pragma solidity ^0.4.18;

contract C {
    // dont know the number of element of the array at the compile time
    // dynamic array
    uint256[] public myArray = [1, 2, 3, 4];

    // delete the element from index i, the slot remains empty
    // this is not efficient, the other elements must be moved to the left
    function delete_from_array(uint256 i) public {
        delete myArray[i];
    }

    // add an element to the dynamic array
    function add(uint256 item) public {
        myArray.push(item);
    }

    function optimized_delete(uint256 index) public {
        if (index >= myArray.length) return;

        for (uint256 i = index; i < myArray.length - 1; i++) {
            myArray[i] = myArray[i + 1];
        }
        myArray.length--;
    }
}
