// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
// Neglect the rubbish you might encounter 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    IERC20 public wageToken;
    IERC20 public bidToken;
    uint public wageAmount;

    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;
    uint public secondHighestBid;

    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);
    event JobCompleted(address winner, uint wageAmount);

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
        address payable beneficiaryAddress,
        address wageTokenAddress,
        address bidTokenAddress,
        uint _wageAmount
    ) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
        wageToken = IERC20(wageTokenAddress);
        bidToken = IERC20(bidTokenAddress);
        wageAmount = _wageAmount;
    }

    function bid(bytes32 blindedBid)
        external
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: 0
        }));
        bidToken.transferFrom(msg.sender, address(this), 1);  // Assume 1 bid token per bid
    }

    function reveal(
        uint[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    )
        external
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(values.length == length);
        require(fakes.length == length);
        require(secrets.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) =
                    (values[i], fakes[i], secrets[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                continue;
            }
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0);
        }
        if (refund > 0) {
            bidToken.transfer(msg.sender, refund);
        }
    }

    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            bidToken.transfer(msg.sender, amount);
        }
    }

    function auctionEnd()
        external
        onlyAfter(revealEnd)
    {
        if (ended) revert AuctionEndAlreadyCalled();
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        bidToken.transfer(beneficiary, secondHighestBid);
    }

    function completeJob()
        external
    {
        require(msg.sender == highestBidder, "Only the highest bidder can complete the job");
        wageToken.transfer(msg.sender, wageAmount);
        emit JobCompleted(msg.sender, wageAmount);
    }

    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            if (value > secondHighestBid) {
                secondHighestBid = value;
            }
            return false;
        }
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
            secondHighestBid = highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
