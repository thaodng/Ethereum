/* if 1 block is confirmed in 15 seconds then 240 new block are confirmed in 1 hour */
/* 60 seconds in a minute, 60 minutes in a hour, 24 hours in a day, 7 days in a week = 604800/15 = 40320 block are mined */

pragma solidity ^0.5.2;

contract Auction {
    //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
    address payable public owner; // who deploy contract also beneficiary
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    uint256 public highestBindingBid;
    address payable public highestBidder; //in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable

    mapping(address => uint256) public bids;
    uint256 bidIncrement;

    constructor() public {
        owner = msg.sender;
        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + 3;

        ipfsHash = "";
        bidIncrement = 1000000000000000000; // 1 ether
    }

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    //a pure function neither reads nor writes to the blockchain
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    //cancel, only by owner
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd returns (bool)
    {
        require(auctionState == State.Running);
        //require(msg.value > 0.001 ether);

        uint256 currentBid = bids[msg.sender] + msg.value;

        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if (currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = msg.sender;
        }
        return true;
    }

    function finalizeAuction() public {
        //the auction has been Ended or Canceled
        require(auctionState == State.Canceled || block.number > endBlock);

        require(msg.sender == owner || bids[msg.sender] > 0);

        // in solidity 0.5.x an address that receives ether (has the transfer function) must be declared payable
        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled) {
            //canceled not ended
            recipient = msg.sender;
            value = bids[msg.sender]; // 0
        } else {
            // ended not canceled
            if (msg.sender == owner) {
                //the owner finalizes the auction
                recipient = owner;
                value = highestBindingBid;
            } else {
                // another user finalizes the auction
                if (msg.sender == highestBidder) {
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    // this is neiher the owner nor the highest bidder
                    recipient = msg.sender;
                    value = bids[msg.sender];
                }
            }
        }

        // sends value to the recipient
        recipient.transfer(value);
    }
}
