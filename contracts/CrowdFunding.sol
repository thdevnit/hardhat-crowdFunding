// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error CrowdFunding__deadLineCrossed();
error CrowdFunding__needMoreEth();
error CrowdFunding_refundFailed();
error CrowdFunding_notOwner();
error CrowdFunding_notAContributor();

contract CrowdFunding {
    struct Request {
        string description;
        address payable receipent;
        uint256 Amount;
        bool completed;
        uint256 numOfVotes;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Request) public s_requests;
    uint256 private s_numOfRequests;

    mapping(address => uint256) private s_contributors;
    uint256 private s_numOfContributors;
    uint256 private constant MIN_CONTRIBUTION = 100 wei;
    uint256 private immutable i_deadLine;
    uint256 private immutable i_targetAmount;
    uint256 private s_raisedAmount;
    address private immutable i_owner;

    constructor(uint256 deadLine, uint256 targetAmount) {
        i_deadLine = block.timestamp + deadLine;
        i_targetAmount = targetAmount;
        i_owner = msg.sender;
    }

    modifier isDeadLineCross() {
        if (block.timestamp > i_deadLine) {
            revert CrowdFunding__deadLineCrossed();
        }
        _;
    }

    modifier isMinContribution() {
        if (msg.value < MIN_CONTRIBUTION) {
            revert CrowdFunding__needMoreEth();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert CrowdFunding_notOwner();
        }
        _;
    }

    modifier isContributor() {
        if (s_contributors[msg.sender] == 0) {
            revert CrowdFunding_notAContributor();
        }
        _;
    }

    function sendEth() public payable isDeadLineCross isMinContribution {
        if (s_contributors[msg.sender] == 0) {
            s_numOfContributors++;
        }
        s_contributors[msg.sender] += msg.value;
        s_raisedAmount += msg.value;
    }

    function refund() public payable {
        require(
            block.timestamp > i_deadLine && s_raisedAmount < i_targetAmount,
            "Refund Condition not met"
        );
        require(s_contributors[msg.sender] > 0, "You are not eligible for refund");
        s_contributors[msg.sender] == 0;

        (bool success, ) = payable(msg.sender).call{value: s_contributors[msg.sender]}("");
        if (!success) {
            revert CrowdFunding_refundFailed();
        }
    }

    function createRequest(
        string memory _description,
        address payable _receipent,
        uint256 _Amount
    ) public onlyOwner {
        Request storage thisRequest = s_requests[s_numOfRequests];
        s_numOfRequests++;

        thisRequest.description = _description;
        thisRequest.receipent = _receipent;
        thisRequest.Amount = _Amount;
        thisRequest.completed = false;
        thisRequest.numOfVotes = 0;
    }

    function voteRequest(uint256 requestIndex) public isContributor {
        Request storage thisRequest = s_requests[requestIndex];

        require(thisRequest.completed == false, "This request has been completed");
        require(thisRequest.voted[msg.sender] == false, "You have already Voted");
        thisRequest.voted[msg.sender] = true;
        thisRequest.numOfVotes++;
    }

    function makePayment(uint256 requestIndex) public payable onlyOwner {
        Request storage newRequest = s_requests[requestIndex];

        require(newRequest.completed == false, "This request has been completed");
        require(newRequest.numOfVotes > s_numOfContributors / 2, "Majority doesn't support");
        newRequest.completed = true;
        (bool success, ) = newRequest.receipent.call{value: newRequest.Amount}("");
        require(success, "Transfer Failed");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContributorBalance(address _contributor) public view returns (uint256) {
        return s_contributors[_contributor];
    }

    function getNumOfContributors() public view returns (uint256 contributors) {
        contributors = s_numOfContributors;
    }

    function getMinContAmount() public pure returns (uint256) {
        return MIN_CONTRIBUTION;
    }

    function getDeadLine() public view returns (uint256) {
        return i_deadLine;
    }

    function getTargetAmount() public view returns (uint256) {
        return i_targetAmount;
    }

    function getRaisedAmount() public view returns (uint256) {
        return s_raisedAmount;
    }

    function getManager() public view returns (address) {
        return i_owner;
    }

    function getNumOfRequest() public view returns (uint256) {
        return s_numOfRequests;
    }

    receive() external payable {
        sendEth();
    }

    fallback() external payable {
        sendEth();
    }
}
