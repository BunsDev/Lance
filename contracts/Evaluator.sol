// contracts/OceanToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract EvaluatorContract {
    struct Evaluator {
        address evaluatorAddress;
        uint256 evaluatorStake;
        string ipfs;
    }

    address[] public availableEvaluators;
    Evaluator[] public evaluators;
    IERC20 public lanceToken;
    uint256 public stakeAmount;
    mapping (address => uint256) public evaluatorKeys;
    mapping (address => bool) public removedEvaluators;

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    event EvaluatorAdded(address evaluatorAddress);
    event EvaluatorRemoved(address evaluatorAddress);
    event StakeIncreased(address evaluatorAddress, uint256 increment);
    event StakeDecreased(address evaluatorAddress, uint256 decrement);


    constructor(IERC20 lanceToken_, uint256 stakeAmount_) {
        lanceToken = lanceToken_;
        stakeAmount = stakeAmount_;
    }

    function transferFromContract(address destinationAddress, uint256 amount) private {
        uint256 erc20balance = lanceToken.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        lanceToken.transfer(destinationAddress, amount);
        emit TransferSent(address(this), destinationAddress, amount);
    }

    function transferToContract(address transferingAddress, uint256 amount) private {
        uint256 erc20balance = lanceToken.balanceOf(transferingAddress);
        require(amount <= erc20balance, "balance is low");
        lanceToken.transferFrom(transferingAddress, address(this), amount);
        emit TransferSent(transferingAddress, address(this), amount);

    }

    function addEvaluator(address evaluator, string calldata ipfs) public  {
        transferToContract(evaluator, stakeAmount);
        uint256 evaluatorIndex = evaluators.length;
        //Add check to see if ipfs works
        evaluators.push(Evaluator({evaluatorAddress: evaluator, evaluatorStake: stakeAmount, ipfs: ipfs}));
        availableEvaluators.push(evaluator);
        evaluatorKeys[evaluator] = evaluatorIndex;
        emit EvaluatorAdded(evaluator);
    }

    function removeEvaluator(address evaluator) external {
        // int evaluatorKey = evaluatorKeys[evaluator];
        // Evaluator storage evaluator_ = evaluators[uint256(evaluatorKey)];
        // uint256 evaluatorRemainingStake = evaluator_.evaluatorStake;
        // evaluator_.evaluatorStake = 0;
        // evaluatorKeys[evaluator] = -1;
        // transferFromContract(evaluator, evaluatorRemainingStake);
        // emit EvaluatorRemoved(evaluator);

        uint256 evaluatorKey = evaluatorKeys[evaluator];
        Evaluator storage evaluator_ = evaluators[evaluatorKey];
        uint256 evaluatorRemainingStake = evaluator_.evaluatorStake;
        evaluator_.evaluatorStake = 0;
        deleteEvaluator(evaluatorKey, evaluator_.evaluatorAddress);
        deleteEvaluatorFromAvailable(evaluatorKey);
        transferFromContract(evaluator, evaluatorRemainingStake);        
    }

    function increaseStake(address evaluator, uint256 increment) external {
        uint256 evaluatorKey = uint256(evaluatorKeys[(evaluator)]);
        Evaluator storage evaluator_ = evaluators[evaluatorKey];
        transferToContract(evaluator, increment);
        evaluator_.evaluatorStake = evaluator_.evaluatorStake + increment;
        emit StakeIncreased(evaluator, increment);
    }

    function decreaseStake(address evaluator, uint256 decrement) external {
        uint256 evaluatorKey = uint256(evaluatorKeys[evaluator]);
        Evaluator storage evaluator_ = evaluators[evaluatorKey];
        evaluator_.evaluatorStake = evaluator_.evaluatorStake - decrement;
        transferFromContract(evaluator, decrement);        
        emit StakeDecreased(evaluator, decrement);
    }

    function getEvaluators() external view returns (Evaluator[] memory) {
        return evaluators;
    }

    function getAvailableEvaluators() external view returns (address[] memory) {
        return availableEvaluators;
    }

    function checkEvaluatorRemoved(address evaluator) external view returns (bool) {
        return removedEvaluators[evaluator];
    }

    function getEvaluatorKey(address evaluator) external view returns (uint256) {
        return evaluatorKeys[evaluator];
    }

    function getEvaluatorAtIndex(uint256 key) external view returns (Evaluator memory) {
        return evaluators[key];
    }    

    function deleteEvaluator(uint256 index, address removedEvaluator) private {
        require(index < evaluators.length);
        Evaluator memory previousLastEvaluator = evaluators[evaluators.length - 1];
        evaluators[index] = evaluators[evaluators.length-1];
        evaluators.pop();

        address previousLastEvaluatorAddress = previousLastEvaluator.evaluatorAddress;
        evaluatorKeys[previousLastEvaluatorAddress] = index;
        removedEvaluators[removedEvaluator] = true;

        if (index == evaluators.length) {
            return;
        }

        for (uint256 i = index + 1; i < evaluators.length; i++) {
                address _evaluatorAddress = evaluators[i].evaluatorAddress;
                evaluatorKeys[_evaluatorAddress] = evaluatorKeys[_evaluatorAddress] - 1;
        }
    }

    function deleteEvaluatorFromAvailable(uint index) private  {
        require(index < availableEvaluators.length);
        availableEvaluators[index] = availableEvaluators[availableEvaluators.length-1];
        availableEvaluators.pop();
    }

    function getRandomEvaluators(uint seed, uint256 number) external view returns (address[5000] memory) {
        address[5000] memory random_evaluators;
        for (uint i = 0; i < number; i++) {
            uint256 randomValue = uint256(keccak256(abi.encode(seed, i))) % availableEvaluators.length;
            random_evaluators[i] = (availableEvaluators[randomValue]);
        }
        return random_evaluators;
    }

    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function punishEvaluatorReduceStake(address evaluator, uint256 decrement) external {
        uint256 evaluatorKey = uint256(evaluatorKeys[evaluator]);
        Evaluator storage evaluator_ = evaluators[evaluatorKey];
        if (decrement >= evaluator_.evaluatorStake) {
            evaluator_.evaluatorStake = 0;
            emit StakeDecreased(evaluator, evaluator_.evaluatorStake);
            return;
        }
        evaluator_.evaluatorStake = evaluator_.evaluatorStake - decrement;
        emit StakeDecreased(evaluator, decrement);
    }

}