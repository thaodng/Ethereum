pragma solidity ^0.5.0;

contract FundRaising {
    address public admin;

    // contributors to the FundRaising Campaign
    mapping(address => uint256) public contributors;
    uint256 public noOfContributors;
    uint256 public minimumContribution;
    uint256 public deadline; // this is a timestamp (seconds)
    
    // amount that must be raised for a successful Campaign    
    uint256 public goal;
    uint256 public raisedAmount = 0;

    // Spending Request created by admin, must be voted by donors
    struct Request {
        address payable recipient;
        string description;
        uint256 value;
        bool completed;
        mapping(address => bool) voters;
        uint256 noOfVoters;
    }

    // dynamic array of requests
    Request[] public requests;

    constructor(uint256 _goal, uint256 _deadline) public {
        goal = _goal;
        deadline = now + _deadline;

        admin = msg.sender;
        minimumContribution = 10;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function contribute() public payable {
        require(now < deadline);
        require(msg.value >= minimumContribution);

        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // refund if goal not met within deadline
    function getRefund() public {
        require(now > deadline);
        require(raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = msg.sender;
        uint256 value = contributors[msg.sender];

        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }

    // admin creates spending request
    function createRequest(string memory _description, address payable _recipient, uint256 _value) public onlyAdmin {
        
        Request memory newRequest = Request({
                description: _description,
                recipient: _recipient,
                value: _value,
                completed: false,
                noOfVoters: 0
            });

        requests.push(newRequest);
    }

    // contributors vote for a request
    function voteRequest(uint256 index) public {
        Request storage thisRequest = requests[index];

        require(contributors[msg.sender] > 0);
        require(thisRequest.voters[msg.sender] == false);

        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    // if voted, owner sends money to the recipient (vendor, seller)
    function makePayment(uint256 index) public onlyAdmin {
        Request storage thisRequest = requests[index];
        require(thisRequest.completed == false);
        require(thisRequest.noOfVoters > noOfContributors / 2); //more than 50% voted

        thisRequest.recipient.transfer(thisRequest.value); //trasfer the money to the recipient
        thisRequest.completed = true;
    }
}
