pragma solidity ^0.4.24;

contract A {
    int256 public x = 8;

    /*function get_x() view returns(int){
        return x;
    }*/

    //default, public function
    function f1() public view returns (int256) {
        return x;
    }

    //private function, can be called only within this contract
    function f2() private view returns (int256) {
        return x;
    }

    function f3() public view returns (int256) {
        int256 a;
        a = f2();
        return a;
    }

    //can be called within this contract and from derived contracts
    function f4() internal view returns (int256) {
        return x;
    }

    //can be called only from the outside (contracts & apps)
    function f5() external view returns (int256) {
        return x;
    }

    function f6() public view returns (int256) {
        int256 b;
        // b = f5(); //error, f5 is an external functoin
        return b;
    }
}

contract B {
    A public contract_a = new A(); //contract B deplays contract A
    int256 public xx = contract_a.f5();
    // int public y = contract_a.f2(); //error, f2 is a private function
    // int public xxx = contract_a.f4(); //error, f4 is internal
}

contract C is A {
    int256 public xx = f4();

    A public a = new A();
    int256 public xxx = a.f5();
}
