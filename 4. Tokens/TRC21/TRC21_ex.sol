contract MyTRC21 is TRC21 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 cap, uint256 minFee) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(msg.sender, cap);
        _changeIssuer(msg.sender);
        _changeMinFee(minFee);
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}