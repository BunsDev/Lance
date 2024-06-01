// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

interface ILance {
    function launchEvaluationContract(address freelancer, bytes calldata jobIPFSHash) external;
}


contract BlindAuction {


    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;
    //Added by me
    uint[] public bidAmounts;
    IERC20 public token;
    ILance public lanceContract;
    address public clientAddress;
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    function getSecondHighestBid(uint[] storage arr) internal view returns (uint) {
    uint highestBid_ = 0;
    uint secondHighestBid_ = 0;
    for (uint i = 0; i < arr.length; i++) {
        uint currentElement = arr[i];
        if (highestBid_ < currentElement) {
            highestBid_ = currentElement;
        }
        if (currentElement != highestBid_) {
            if ( secondHighestBid_ < currentElement) {
                secondHighestBid_ = currentElement;
            }
        }

    }
    if (secondHighestBid_ == 0) {
        return highestBid_;
    } else {
        return secondHighestBid_;
    }

}

    function transferFromContract(address destinationAddress, uint256 amount) private {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance is low");
        token.transfer(destinationAddress, amount);
        emit TransferSent(address(this), destinationAddress, amount);
    }

    function transferToContract(address transferingAddress, uint256 amount) private {
        uint256 erc20balance = token.balanceOf(transferingAddress);
        require(amount <= erc20balance, "balance is low");
        token.transferFrom(transferingAddress, address(this), amount);
        emit TransferSent(transferingAddress, address(this), amount);

    }

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;
    uint public secondHighestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);


    error TooEarly(uint time);
    error TooLate(uint time);
    error AuctionEndAlreadyCalled();

    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor(
        uint biddingTime,
        uint revealTime,
        IERC20 bidToken_,
        address lanceContractAddress
        address payable clientAddress 
    ) {
        clientAddress = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
        token = bidToken_;
        lanceContract = ILance(lanceContractAddress);
    }

    function bid(address bidder, uint256 overbid, bytes32 blindedBid)
        external
        // onlyBefore(biddingEnd)
    {
        bids[bidder].push(Bid({
            blindedBid: blindedBid,
            deposit: overbid
        }));
        transferToContract(bidder, overbid);
    }

    function reveal(
        uint[] calldata values,
        bytes32[] calldata secrets,
        address bidder
    )
        external
        // onlyAfter(biddingEnd)
        // onlyBefore(revealEnd)
    {
        uint length = bids[bidder].length;
        require(values.length == length);
        require(secrets.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[bidder][i];
            (uint value, bytes32 secret) =
                    (values[i], secrets[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, secret))) {
                // Bid was not actually revealed.
                // Do not refund deposit.
                continue;
            }
            refund += bidToCheck.deposit;
            if (bidToCheck.deposit >= value) {
                if (placeBid(bidder, value))
                    refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0);
        }
        transferFromContract(bidder, refund);
    }

    /// Withdraw a bid that was overbid.
    function withdraw(address bidder) external {
        uint amount = pendingReturns[bidder];
        if (amount > 0) {
            pendingReturns[bidder] = 0;
            transferFromContract(bidder, amount);
        }
    }

    function auctionEnd()
        external
        // onlyAfter(revealEnd)
    {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        // beneficiary.transfer(highestBid);
        secondHighestBid = getSecondHighestBid(bidAmounts);
        uint pendingRefund = highestBid - secondHighestBid;
        transferFromContract(highestBidder, pendingRefund);   
    }


    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        bidAmounts.push(value);
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != address(0)) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}