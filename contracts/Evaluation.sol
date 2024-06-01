// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./OpenZepplinRemovedContracts.sol";


interface IEvaluator {

    struct Evaluator {
        address evaluatorAddress;
        uint256 evaluatorStake;
        string ipfs;
    }
    function getAvailableEvaluators() external view returns (address[] memory);
    function getRandomEvaluators(uint seed, uint256 number) external view returns (address[5000] memory);
    function punishEvaluatorReduceStake(address evaluator, uint256 decrement) external;
}

contract Evaluation {
    
    enum Grade {
        A,
        B,
        C,
        D,
        E,
        F
    }
    mapping(address => uint) evaluatorKeys;
    uint B_start;
    uint C_start;
    uint D_start;
    uint E_start;
    uint F_start;

    uint fund_allocation_A;
    uint fund_allocation_B;
    uint fund_allocation_C;
    uint fund_allocation_D;
    uint fund_allocation_E;
    uint fund_allocation_F;

    address workerAddress;
    address clientAddress;

    uint wage;


    Grade grade;
    IEvaluator evaluatorContract;
    address[] evaluators;
    bool[] evaluatorsSubmitted;
    uint256 public ownerScore;
    bool public ownerSubmitted;
    uint256[] public evaluatorAlgorithmicScore;
    uint256[] public evaluatorHeuristicScore;
    uint public medianHeuristic;
    uint public medianAlgorithmic;
    uint public lowerIQRAlgo;
    uint public upperIQRAlgo;
    uint public lowerIQRHeuristic;
    uint public upperIQRHeuristic;
    uint public averageHeuristic;
    uint public averageAlgo;
    uint public overallScore;
    uint public evaluatorOverall;
    uint public fees;
    PaymentSplitter clientWorkerSplitter;
    uint public maxStakeLosable;
    uint public decimals;
    uint public heuristicAllocation;
    uint public algorithmicAllocation;
    uint public evaluatorAllocation;
    uint public clientAllocation;



    IERC20 lanceToken;
    IERC20 bidToken;

    uint256 sharesForMedian;
    uint256 sharesForNonMedian;
    
    uint[] private data;

    


    constructor(
     address evaluatorContractAddress,
     IERC20 lanceToken_, IERC20 bidToken_, 
     uint fees_, 
     uint numberOfEvaluators_, 
     uint decimals_,
     uint heuristicAllocation_,
     uint evaluatorAllocation_,
     uint sharesForMedian_,
     uint sharesForNonMedian_
     ) {
        evaluatorContract = IEvaluator(evaluatorContractAddress);
        lanceToken = lanceToken_;
        bidToken = bidToken_;
        fees = fees_;
        evaluatorAlgorithmicScore = new uint[](numberOfEvaluators_);
        evaluatorHeuristicScore = new uint[](numberOfEvaluators_);
        evaluatorsSubmitted  = new bool[](numberOfEvaluators_);
        decimals = decimals_;
        heuristicAllocation = heuristicAllocation_;
        algorithmicAllocation = 100 * decimals - heuristicAllocation_;
        evaluatorAllocation = evaluatorAllocation_;
        clientAllocation = 100 * decimals - evaluatorAllocation;
        sharesForMedian = sharesForMedian_;
        sharesForNonMedian = sharesForNonMedian_;

        populateEvaluators(1000, numberOfEvaluators_);
    }

    function getEvaluatorScores() public view returns (uint[] memory, uint[] memory) {
        return (evaluatorAlgorithmicScore, evaluatorHeuristicScore);
    }

    function submitEvaluatorScore(address evaluator, uint algo_score, uint heuristic_score) public {
        uint evaluatorKey = evaluatorKeys[evaluator];
        evaluatorAlgorithmicScore[evaluatorKey] = algo_score;
        evaluatorHeuristicScore[evaluatorKey] = heuristic_score;
        evaluatorsSubmitted[evaluatorKey] = true;
    }

    function submitOwnerScore(address owner, uint score) public {
        //Require that it is the owner that submits
        ownerScore = score;
    }

    function evaluate() public {
        averageAlgo = evaluateAlgorithmicTests();
        averageHeuristic = evaluateHeuristicTests();
        
        uint algorithmicRatio = divide(algorithmicAllocation, algorithmicAllocation + heuristicAllocation);
        uint heuristicRatio = divide(heuristicAllocation, algorithmicAllocation + heuristicAllocation);
        evaluatorOverall = multiply(algorithmicRatio, averageAlgo) + multiply((averageHeuristic), heuristicRatio);

        overallScore = multiply(divide(evaluatorAllocation, (evaluatorAllocation + clientAllocation)), evaluatorOverall) +
        multiply(divide(clientAllocation, (evaluatorAllocation + clientAllocation)), ownerScore);

        if (overallScore <= 100 && overallScore >= B_start) {
            grade = Grade.A;
        } else if (overallScore < B_start && overallScore >= C_start) {
            grade = Grade.B;
        } else if (overallScore < B_start && overallScore >= D_start) {
            grade = Grade.C;        
        } else if (overallScore < B_start && overallScore >= E_start) {
            grade = Grade.D;          
        } else if (overallScore < B_start && overallScore >= F_start) {
            grade = Grade.E;            
        } else if (overallScore < F_start && overallScore >= 0) {
            grade = Grade.F;
        }
        rewardEvaluators();
    }

    function evaluateAlgorithmicTests() public returns (uint) {
        (lowerIQRAlgo, upperIQRAlgo) = getIQR(evaluatorAlgorithmicScore);
        return calculateAverage(evaluatorAlgorithmicScore, lowerIQRAlgo, upperIQRAlgo);
    }

    function evaluateHeuristicTests() public returns (uint) {
        (lowerIQRHeuristic, upperIQRHeuristic) = getIQR(evaluatorHeuristicScore);
        return calculateAverage(evaluatorHeuristicScore, lowerIQRHeuristic, upperIQRHeuristic);
    }

    function transferLanceFromContract(address destinationAddress, uint256 amount) private {
        uint256 erc20balance = lanceToken.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        lanceToken.transfer(destinationAddress, amount);
    }

    
    function transferLanceBidFromContract(address destinationAddress, uint256 amount) private {
        uint256 erc20balance = bidToken.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        bidToken.transfer(destinationAddress, amount);
    }

    function populateEvaluators(uint seed, uint amount) public  {
        address[5000] memory randomEvaluators_ =  evaluatorContract.getRandomEvaluators(seed, amount);
        for (uint i = 0; i < amount; i++) {
            evaluators.push(randomEvaluators_[i]);
            evaluatorKeys[randomEvaluators_[i]] = i;
        }
    }

    function getEvaluators() public view returns (address[] memory) {
        return evaluators;
    }

    function getMedian(uint256[] memory array) private returns (uint256) {
        if (array.length == 0) {
            return 0;
        }
        UintArray(array);
        sort();
        if (data.length % 2 == 0) {
            uint medianIndice1 = data.length/2;
            uint medianIndice2 = medianIndice1 - 1;
            uint median1 = data[medianIndice1];
            uint median2 = data[medianIndice2];
            return ((median1 + median2))/2;
        } else {
            uint medianIndex = data.length/2;
            return data[medianIndex];
        }
    }

    function getIQR(uint[] memory arr) public returns (uint, uint) {
       UintArray(arr);
       sort();
       uint[] memory upperHalf = getUpperHalf(data);
       uint[] memory lowerHalf = getLowerHalf(data); 
       uint q3 = getMedian(upperHalf);
       uint q1 = getMedian(lowerHalf);
       uint IQR = q3 - q1;
       uint upperIQR =  q3 + ((IQR * 3)/2);
       uint lowerIQR;
       if (q1 < ((IQR * 3)/2)) {
        lowerIQR = 0;
       } else {
        lowerIQR =  q1 - ((IQR * 3)/2);
       }
       return (lowerIQR, upperIQR);
    }

    function UintArray(uint[] memory _data) public {
        data = new uint[](_data.length);
        for(uint i = 0;i < _data.length;i++) {
            data[i] = _data[i];
        }
    }

    function sort_item(uint pos) internal returns (bool) {
        uint w_min = pos;
        for(uint i = pos;i < data.length;i++) {
            if(data[i] < data[w_min]) {
                w_min = i;
            }
        }
        if(w_min == pos) return false;
        uint tmp = data[pos];
        data[pos] = data[w_min];
        data[w_min] = tmp;
        return true;
    }
    
    /**
     * @dev Sort the array
     */
    function sort() public {
        for(uint i = 0;i < data.length-1;i++) {
            sort_item(i);
        }
    }

    function getLowerHalf(uint[] memory arr) private pure returns (uint[] memory) {
        uint arrLength = arr.length/2;
        uint[] memory lowerHalf = new uint[](arrLength);
        for (uint i = 0; i < arrLength; i++) {
            lowerHalf[i] = (arr[i]);
        }
        return lowerHalf;
    }

    function getUpperHalf(uint[] memory arr) private pure returns (uint[] memory)  {
        uint arrLength = arr.length/2;
        uint[] memory upperHalf = new uint[](arrLength);
        if (arr.length % 2 == 0) {
            for (uint i = arrLength; i < arr.length; i++) {
                upperHalf[i-arrLength] = (arr[i]);
            }
        return upperHalf;            
        } else {
            for (uint i = arrLength + 1; i < arr.length; i++) {
                upperHalf[i-arrLength-1] = (arr[i]);
            }
        return upperHalf;
        }
    }

    function rewardEvaluators() public {
        address[] memory payees = new address[](evaluatorHeuristicScore.length);
        uint[] memory shares = new uint[](evaluatorHeuristicScore.length);
        uint[] memory repercursions = new uint[](evaluatorHeuristicScore.length);
        for (uint i = 0; i < evaluatorHeuristicScore.length; i++) {
            payees[i] = evaluators[i];
            if (evaluatorHeuristicScore[i] > lowerIQRHeuristic && evaluatorHeuristicScore[i] < upperIQRHeuristic) {
                if (evaluatorHeuristicScore[i] == medianHeuristic) {
                    shares[i] = sharesForMedian;
                } else {
                    shares[i] = sharesForNonMedian;
                }
            } else {
                shares[i] = 1;
                repercursions[i] = calculateAbsoluteError(medianHeuristic, evaluatorHeuristicScore[i]);
            }
        }

        for (uint i = 0; i < evaluatorAlgorithmicScore.length; i++) {
            if (evaluatorAlgorithmicScore[i] > lowerIQRAlgo && evaluatorAlgorithmicScore[i] < upperIQRAlgo) {
                if (evaluatorAlgorithmicScore[i] == medianAlgorithmic) {
                    shares[i] = shares[i] + sharesForMedian;
                } else {
                    shares[i] = shares[i] + sharesForNonMedian;
                    repercursions[i] = repercursions[i] + calculateAbsoluteError(medianHeuristic, evaluatorHeuristicScore[i]);
                }
            } 
        }

        PaymentSplitter paymentSplitter = new PaymentSplitter(payees, shares);
        transferLanceBidFromContract(address(paymentSplitter), fees);
        transferLanceFromContract(address(paymentSplitter), fees);
        
        for (uint i = 0; i < payees.length; i++) {
            paymentSplitter.release(lanceToken,payees[i]);
            paymentSplitter.release(bidToken, payees[i]);
        }

        for (uint i = 0; i < repercursions.length; i++) {
            if (repercursions[i] == 0) {
                return;
            }
            uint stakeReduction = repercursions[i] * maxStakeLosable;
            evaluatorContract.punishEvaluatorReduceStake(payees[i], stakeReduction);
        }

    }

    function calculateAbsoluteError(uint256 value1, uint256 value2) private pure returns (uint256) {
        if (value1 > value2) {
            return value1 - value2;
        } else {
            return value2 - value1;
        }
    }

    function calculateAverage(uint[] memory arr, uint lowerBound, uint upperBound) private pure returns (uint) {
        uint total = 0;
        uint rejected = 0;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] > upperBound || arr[i] < lowerBound) {
                rejected = rejected + 1;
                continue;
            }
            total = total + arr[i];
        }
        return total/(arr.length - rejected);
    }

    function getAllocationArray(uint256 allocation) private view returns (uint256[] memory) {
        uint256[] memory allocationArray;
        allocationArray[0] = allocation;
        allocationArray[1] = 100 * decimals - allocation;
        return allocationArray;
    }

    function settle() public {
        address[] memory clientWorkerAddresses = new address[](2);
        clientWorkerAddresses[0] = clientAddress;
        clientWorkerAddresses[1] = workerAddress;
        if (grade == Grade.A) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_A));
        } else if (grade == Grade.B) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_B));
        } else if (grade == Grade.C) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_C));
        } else if (grade == Grade.D) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_D));
        } else if (grade == Grade.E) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_E));
        } else if (grade == Grade.F) {
            clientWorkerSplitter = new PaymentSplitter(clientWorkerAddresses, getAllocationArray(fund_allocation_F));
        }
        transferLanceFromContract(address(clientWorkerSplitter), wage);
        clientWorkerSplitter.release(lanceToken, clientAddress);
        clientWorkerSplitter.release(lanceToken, workerAddress);
    }

    function multiply(uint value1, uint value2) private view returns (uint) {
        return (value1 * value2)/decimals; 
    }

    function divide(uint value1, uint value2) private view returns (uint) {
        return (value1*decimals / value2); 
    }

}