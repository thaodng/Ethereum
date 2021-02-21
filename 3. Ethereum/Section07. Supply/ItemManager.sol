pragma solidity ^0.6.0;

import "./Item.sol";
import "./Ownable.sol";

contract ItemManager is Ownable {
    enum SupplyChainSteps {Created, Paid, Delivered}
    event SupplyChainStep(uint256 _itemIndex, uint256 _step, address _address);

    struct S_Item {
        string _identifier;
        // uint _itemPrice;
        Item _item;
        ItemManager.SupplyChainSteps _step;
    }

    mapping(uint256 => S_Item) public items;
    uint256 index;

    function createItem(string memory _identifier, uint256 _priceInWei)
        public
        onlyOwner
    {
        Item item = new Item(this, _priceInWei, index);
        items[index]._identifier = _identifier;
        // items[index]._itemPrice = _itemPrice;
        items[index]._item = item;
        items[index]._step = SupplyChainSteps.Created;
        emit SupplyChainStep(index, uint256(items[index]._step), address(item));
        index++;
    }

    function triggerPayment(uint256 _index) public payable {
        Item item = items[_index]._item;
        require(
            address(item) == msg.sender,
            "Only items are allowed to update themselves"
        );
        require(item.priceInWei() == msg.value, "Not fully paid yet"); // only full payment accepted
        require(
            items[index]._step == SupplyChainSteps.Created,
            "Item is further in the supply chain"
        );
        items[_index]._step = SupplyChainSteps.Paid;
        emit SupplyChainStep(
            _index,
            uint256(items[_index]._step),
            address(item)
        );
    }

    function triggerDelivery(uint256 _index) public onlyOwner {
        require(
            items[_index]._step == SupplyChainSteps.Paid,
            "Item is further in the supply chain"
        );
        items[_index]._step = SupplyChainSteps.Delivered;
        emit SupplyChainStep(
            _index,
            uint256(items[_index]._step),
            address(items[_index]._item)
        );
    }
}
