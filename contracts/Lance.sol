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
    uint fund_allocation_A = 0;
    uint fund_allocation_B = 2000;
    uint fund_allocation_C = 4000;
    uint fund_allocation_D = 6000;
    uint fund_allocation_E = 8000;
    uint fund_allocation_F = 10000;
    uint B_start = 7000;
    uint C_start = 6000;
    uint D_start = 5000;
    uint E_start = 4500;
    uint F_start = 4000;

    //Auction DAO Variables
    uint biddingTime = 10000;
    uint revealTime = 10000;


    
    function CREATE_JOB(uint wage, uint jobDetailsIPFSHash) public {
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
        job_mapping[ipfsHash].job_state = JobState.Submitted;  
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

    function launchEvaluationContract(address freelancer, bytes calldata jobIPFSHash) external {
        uint wage = job_mapping[jobIPFSHash].wage;
        address client = job_mapping[jobIPFSHash].client;

        job_evaluation[jobIPFSHash] = new Evaluation(evaluatorContractAddress, lanceToken, lanceBidToken, fees_, numberOfEvaluators_,
         decimals_, heuristicAllocation_, evaluatorAllocation_, sharesForMedian_, sharesForNonMedian_, totalBids, wage, fund_allocation_A, fund_allocation_B, 
         fund_allocation_C, fund_allocation_D, fund_allocation_E, fund_allocation_F, B_start, C_start, D_start, E_start, F_start, freelancer, client);
    }

    function setJobState(bytes calldata jobIPFSHash, uint jobStateNumber) external {
        Job storage _job = job_mapping[jobIPFSHash];
        if (jobStateNumber == 0) {
            _job.job_state = JobState.Auction_Bidding;
        } else if (jobStateNumber == 1) {
            _job.job_state = JobState.Auction_Reveal;
        } else if (jobStateNumber == 2) {
            _job.job_state = JobState.Work_In_Progress;
        } else if (jobStateNumber == 3) {
            _job.job_state = JobState.Submitted;
        } else if (jobStateNumber == 4) {
            _job.job_state = JobState.Evaluation_In_Progress;
        } else if (jobStateNumber == 5) {
            _job.job_state = JobState.Settled;
        }
    }

    //DAO Stuff Here
    // Setter functions for Evaluation DAO Variables
    function setFees(uint _fees) public {
        fees_ = _fees;
    }

    function setNumberOfEvaluators(uint _numberOfEvaluators) public {
        numberOfEvaluators_ = _numberOfEvaluators;
    }

    function setDecimals(uint _decimals) public {
        decimals_ = _decimals;
    }

    function setHeuristicAllocation(uint _heuristicAllocation) public {
        heuristicAllocation_ = _heuristicAllocation;
    }

    function setEvaluatorAllocation(uint _evaluatorAllocation) public {
        evaluatorAllocation_ = _evaluatorAllocation;
    }

    function setSharesForMedian(uint _sharesForMedian) public {
        sharesForMedian_ = _sharesForMedian;
    }

    function setSharesForNonMedian(uint _sharesForNonMedian) public {
        sharesForNonMedian_ = _sharesForNonMedian;
    }

    function setFundAllocationA(uint _fund_allocation_A) public {
        fund_allocation_A = _fund_allocation_A;
    }

    function setFundAllocationB(uint _fund_allocation_B) public {
        fund_allocation_B = _fund_allocation_B;
    }

    function setFundAllocationC(uint _fund_allocation_C) public {
        fund_allocation_C = _fund_allocation_C;
    }

    function setFundAllocationD(uint _fund_allocation_D) public {
        fund_allocation_D = _fund_allocation_D;
    }

    function setFundAllocationE(uint _fund_allocation_E) public {
        fund_allocation_E = _fund_allocation_E;
    }

    function setFundAllocationF(uint _fund_allocation_F) public {
        fund_allocation_F = _fund_allocation_F;
    }

    function setBStart(uint _B_start) public {
        B_start = _B_start;
    }

    function setCStart(uint _C_start) public {
        C_start = _C_start;
    }

    function setDStart(uint _D_start) public {
        D_start = _D_start;
    }

    function setEStart(uint _E_start) public {
        E_start = _E_start;
    }

    function setFStart(uint _F_start) public {
        F_start = _F_start;
    }

    // Setter functions for Auction DAO Variables
    function setBiddingTime(uint _biddingTime) public {
        biddingTime = _biddingTime;
    }

    function setRevealTime(uint _revealTime) public {
        revealTime = _revealTime;
    }
}



