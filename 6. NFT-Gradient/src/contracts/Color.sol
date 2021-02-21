pragma solidity ^0.5.0;

import "./ERC721Full.sol";

contract Color is ERC721Full {
  string[] public colors;
  mapping(string => bool) _colorExists;

  // calling parent constructor then set this constructor to public
  constructor() ERC721Full("Color", "COLOR") public {}

  // e.g. color = "#FFFFFF"
  function mint(string memory _color) public {
    require(!_colorExists[_color]);
    uint _id = colors.push(_color); // in solidity version > 6.0 color.push don't return anymore
    _mint(msg.sender, _id); // who mint this token and what id of this
    _colorExists[_color] = true;
  }
}
