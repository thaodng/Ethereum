pragma solidity ^0.4.24;

contract Global {
    uint256 public _now = block.timestamp;
    uint256 public block_number = block.number;
    uint256 public difficulty = block.difficulty;
    uint256 public gaslimit = block.gaslimit;

    function get_transaction_gas_price() public view returns (uint256) {
        return tx.gasprice;
    }

    //this function calculates how much gas consumes operations inside its body
    function f() public view returns (uint256) {
        //transaction gas left to be consumed by this transaction
        uint256 start = gasleft();

        /* 800 only for this execution. Then 21000 gas for sending transaction */
        uint256 j = 5;
        for (uint256 i = 0; i < 10; i++) {
            j++;
        }

        return start - gasleft();
    }
}
