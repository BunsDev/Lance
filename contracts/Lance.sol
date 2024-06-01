// contracts/OceanToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Evaluation.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vickery.sol";

contract Lance {

    enum JobState {
        Auction_Bidding,
        Auction_Reveal,
        Work_In_Progress,
        Submitted,
        Evaluatino_In_Progress,
        Settled
    }

    struct Job {
        uint wage;
        bytes jobDetailsHash;
        address creator;
        JobState job_state;
        uint index;
    }

    mapping(bytes=>Job) job_mapping;
    mapping(bytes=>Evaluation) job_evaluation;
    mapping(bytes=>BlindAuction) job_auction;
    IERC20 lanceToken;
    IERC20 lanceBidToken;
    uint totalJobs = 0;
    Job[] public jobs;
    mapping(address=>Job[]) job_bids;
    mapping(address=>Job[]) job_posts;
    address evaluatorContractAddress;

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);


    //Key DAO Variables Evaluation
     uint fees_ = 500;
     uint numberOfEvaluators_ = 3;
     uint decimals_ = 100;
     uint heuristicAllocation_ = 4000;
     uint evaluatorAllocation_ = 7000;
     uint sharesForMedian_ = 7000;
     uint sharesForNonMedian_ = 3000;


    
    function CREATE_JOB(uint wage, uint jobDetailsIPFSHash, uint biddingTime, uint revealTime) public {
        transferToContract_(msg.sender, wage);
        BlindAuction vickeryAuction = new BlindAuction(biddingTime, revealTime, lanceBidToken);
        Job newJob = Job({
            wage: wage,
            jobDetailsHash: jobDetailsIPFSHash,
            job_state: JobState.Auction_Bidding,
            index: totalJobs,
            creator: msg.sender
        });
        job_mapping[jobDetailsIPFSHash] = newJob;
        job_auction[jobDetailsIPFSHash] = vickeryAuction;
        jobs.push(newJob);
        totalJobs = totalJobs + 1;
    }

    function getJobPosts() public view returns (Job[] memory) {
        return jobs;
    }

    function getJobBids() public view returns(Job[] memory) {
        address requester = msg.sender;
        return job_bids[requester];
    }

    function getUserJobPosts() public view returns(Job[] memory) {
        address requester = msg.sender;
        return job_posts[requester];
    }

    function CREATE_BID(bytes calldata ipfsHash, uint overbid, bytes blindedBid) public {
        //Access the job
        //Check whether auction is still on
        job_auction[ipfsHash].bid(msg.sender, overbid, blindedBid);
    }

    function REVEAL_BID(bytes calldata ipfsHash, uint[] values, bytes[] secrets) public {
        //Make sure job state is reveal
        job_auction[ipfsHash].reveal(values, secrets,  msg.sender);
    }

    //Called at the end of evaluation
    //Called by Chainlink keepers
    function evaluateJob(bytes calldata ipfsHash) public {
        //Modifier to make sure it is the correct person calling this
        job_evaluation[ipfsHash].evaluate();        
    }
    
    function getSingleJob(bytes calldata ipfsHash) public view returns (Job memory)  {
        return job_mapping[ipfsHash];
    }

    function OWNER_SUBMIT(bytes calldata ipfsHash, uint score) public {
        //Modifier here to check if supervisor
        //Modifier to check if the score is between 1 and 100
        job_evaluation[ipfsHash].submitOwnerScore(msg.sender, score);        
    }

    function EVALUATOR_SUBMIT(bytes calldata ipfsHash, uint256 heuristicScores, uint256 algorithmicScores) public {
        //Modifier to check if supervisor
        //Modifier to check if the score is between 1 and 100
        job_evaluation[ipfsHash].submitEvaluatorScore(msg.sender, heuristicScores, algorithmicScores);         
    }

    function getJobState(bytes calldata ipfsHash) public view returns (JobState) {
        return job_mapping[ipfsHash].job_state;
    }

    function SUBMIT_JOB(bytes calldata ipfsHash) public {
        //Modifier to check if its the freelancer that submitted the job
        job_mapping[ipfsHash].job_state = JobState.Settled;  
    }
    
    function transferFromContract_(address destinationAddress, uint256 amount) private {
        uint256 erc20balance = lanceToken.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        lanceToken.transfer(destinationAddress, amount);
        emit TransferSent(address(this), destinationAddress, amount);
    }

    
    function transferToContract_(address transferingAddress, uint256 amount) private {
        uint256 erc20balance = lanceToken.balanceOf(transferingAddress);
        require(amount <= erc20balance, "balance is low");
        lanceToken.transferFrom(transferingAddress, address(this), amount);
        emit TransferSent(transferingAddress, address(this), amount);
    }


    //  uint fees_ = 500;
    //  uint numberOfEvaluators_ = 3;
    //  uint decimals_ = 100;
    //  uint heuristicAllocation_ = 4000;
    //  uint evaluatorAllocation_ = 7000;
    //  uint sharesForMedian_ = 7000;
    //  uint sharesForNonMedian_ = 3000;
    function launchEvaluationContract(bytes calldata jobIPFSHash, JobState jobState) external {
        uint wage = job_mapping[jobIPFSHash].wage;
        job_evaluation[jobIPFSHash] = new Evaluation(evaluatorContractAddress, lanceToken, lanceBidToken, fees_, numberOfEvaluators_,
         decimals_, heuristicAllocation_, evaluatorAllocation_, sharesForMedian_, sharesForNonMedian_, totalBids, wage);
    }

    function setJobState(bytes calldata jobIPFSHash, JobState jobState) external {
        job_mapping[jobIPFSHash].job_state = jobState;
    }



}