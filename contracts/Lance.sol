// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Evaluation.sol";
import "./Vickery.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
       


contract Lance is Ownable, VRFConsumerBaseV2Plus  {

    enum JobState {
        Auction_Bidding,
        Auction_Reveal,
        Work_In_Progress,
        Submitted,
        Evaluation_In_Progress,
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
    mapping(bytes =>uint) total_bids;
    mapping(uint=>bytes) request_id_job;
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
     uint fees___ = 500;
     uint numberOfEvaluators___ = 3;
     uint decimals___ = 100;
     uint heuristicAllocation___ = 4000;
     uint evaluatorAllocation___ = 7000;
     uint sharesForMedian___ = 7000;
     uint sharesForNonMedian___ = 3000;
    uint fund_allocation_A__ = 0;
    uint fund_allocation_B__ = 2000;
    uint fund_allocation_C__ = 4000;
    uint fund_allocation_D__ = 6000;
    uint fund_allocation_E__ = 8000;
    uint fund_allocation_F__ = 10000;
    uint B_start__ = 7000;
    uint C_start__ = 6000;
    uint D_start__ = 5000;
    uint E_start__ = 4500;
    uint F_start__ = 4000;

    //Auction DAO Variables
    uint biddingTime = 10000;
    uint revealTime = 10000;

    constructor() VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        s_subscriptionId = 34819016671288333405034461087610416166059451287055882005961350888421489571689;
    } 


    
    function CREATE_JOB(uint wage, bytes memory jobDetailsIPFSHash) public {
        transferToContract_(msg.sender, wage);
        BlindAuction vickeryAuction = new BlindAuction(biddingTime, revealTime,
         lanceBidToken, address(this), payable(msg.sender), jobDetailsIPFSHash, decimals___, fees___);
        Job memory newJob = Job({
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

    function CREATE_BID(bytes memory ipfsHash, uint overbid, bytes32 blindedBid) public {
        //Access the job
        //Check whether auction is still on
        job_auction[ipfsHash].bid(msg.sender, overbid, blindedBid);
    }

    function REVEAL_BID(bytes calldata ipfsHash, uint[] calldata values, bytes32[] calldata secrets) public {
        //Make sure job state is reveal
        job_auction[ipfsHash].reveal(values, secrets,  msg.sender);
    }

    function setTotalBids(bytes calldata ipfsHash, uint bidAmount) external {
        total_bids[ipfsHash] = total_bids[ipfsHash] + bidAmount;
    }

    //Called at the end of evaluation
    //Called by Chainlink keepers
    // function evaluateJob(bytes calldata ipfsHash) public {
    //     //Modifier to make sure it is the correct person calling this
    //     job_evaluation[ipfsHash].evaluate();        
    // }
    
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

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        bytes memory jobIPFS = request_id_job[_requestId];
        Evaluation evaluation = job_evaluation[jobIPFS];
        evaluation.populateEvaluators(_randomWords, evaluation.numberOfEvaluators());
    }

    function launchEvaluationContract(address freelancer, bytes calldata jobIPFSHash) external {
        uint wage = job_mapping[jobIPFSHash].wage;
        address client = job_mapping[jobIPFSHash].creator;
        uint totalBids = total_bids[jobIPFSHash];

        uint[20] memory variables = [
         fees___, numberOfEvaluators___,
         decimals___, heuristicAllocation___, evaluatorAllocation___, 
         sharesForMedian___, sharesForNonMedian___, totalBids, wage, 
         fund_allocation_A__, fund_allocation_B__, 
         fund_allocation_C__, fund_allocation_D__, 
         fund_allocation_E__, fund_allocation_F__, B_start__,
         C_start__, D_start__, E_start__, F_start__
         ];

        job_evaluation[jobIPFSHash] = new Evaluation(evaluatorContractAddress, address(this), lanceToken, lanceBidToken, variables, freelancer, client, jobIPFSHash);
    }


    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; 
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; 

    uint256 public s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 2;


    function requestRandomWords(
        bool enableNativePayment,
        bytes calldata jobIPFS
    ) private returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        request_id_job[requestId] = jobIPFS;
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
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

    function getSeedAndPopulate(bytes memory jobIPFS) external {
        //Get seed from chainlink
        //Call evaluation populate function
        requestRandomWords(false, jobIPFS);
        //Fulfil function
    }


        // Setter functions for Key DAO Variables
    function setFees(uint _fees) public onlyOwner {
        fees___ = _fees;
    }

    function setNumberOfEvaluators(uint _numberOfEvaluators) public onlyOwner {
        numberOfEvaluators___ = _numberOfEvaluators;
    }

    function setDecimals(uint _decimals) public onlyOwner {
        decimals___ = _decimals;
    }

    function setHeuristicAllocation(uint _heuristicAllocation) public onlyOwner {
        heuristicAllocation___ = _heuristicAllocation;
    }

    function setEvaluatorAllocation(uint _evaluatorAllocation) public onlyOwner {
        evaluatorAllocation___ = _evaluatorAllocation;
    }

    function setSharesForMedian(uint _sharesForMedian) public onlyOwner {
        sharesForMedian___ = _sharesForMedian;
    }

    function setSharesForNonMedian(uint _sharesForNonMedian) public onlyOwner {
        sharesForNonMedian___ = _sharesForNonMedian;
    }

    function setFundAllocationA(uint _fund_allocation_A) public onlyOwner {
        fund_allocation_A__ = _fund_allocation_A;
    }

    function setFundAllocationB(uint _fund_allocation_B) public onlyOwner {
        fund_allocation_B__ = _fund_allocation_B;
    }

    function setFundAllocationC(uint _fund_allocation_C) public onlyOwner {
        fund_allocation_C__ = _fund_allocation_C;
    }

    function setFundAllocationD(uint _fund_allocation_D) public onlyOwner {
        fund_allocation_D__ = _fund_allocation_D;
    }

    function setFundAllocationE(uint _fund_allocation_E) public onlyOwner {
        fund_allocation_E__ = _fund_allocation_E;
    }

    function setFundAllocationF(uint _fund_allocation_F) public onlyOwner {
        fund_allocation_F__ = _fund_allocation_F;
    }

    function setBStart(uint _B_start) public onlyOwner {
        B_start__ = _B_start;
    }

    function setCStart(uint _C_start) public onlyOwner {
        C_start__ = _C_start;
    }

    function setDStart(uint _D_start) public onlyOwner {
        D_start__ = _D_start;
    }

    function setEStart(uint _E_start) public onlyOwner {
        E_start__ = _E_start;
    }

    function setFStart(uint _F_start) public onlyOwner {
        F_start__ = _F_start;
    }

    // Setter functions for Auction DAO Variables
    function setBiddingTime(uint _biddingTime) public onlyOwner {
        biddingTime = _biddingTime;
    }

    function setRevealTime(uint _revealTime) public onlyOwner {
        revealTime = _revealTime;
    }
}



