// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlanceWageToken is ERC20, Ownable {
    uint256 private _cap;
    
    constructor(uint256 cap_) ERC20("Chainlance Wage Token", "CWT") Ownable(msg.sender) {
        require(cap_ > 0, "Cap is 0");
        _cap = cap_;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Cap exceeded");
        _mint(to, amount);
    }
}

contract ChainlanceBidToken is ERC20, Ownable {
    uint256 private _cap;
    
    constructor(uint256 cap_) ERC20("Chainlance Bid Token", "CBT") Ownable(msg.sender){
        require(cap_ > 0, "Cap is 0");
        _cap = cap_;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= cap(), "Cap exceeded");
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

contract ChainlanceVickreyAuction is Ownable {
    
    struct Auction {
        address payable creator;
        uint256 wage;
        uint256 endAuction;
        bool settled;
        address highestBidder;
        uint256 highestBid;
        uint256 secondHighestBid;
        mapping(address => uint256) bids;
        address[] bidders;
    }

    ChainlanceWageToken public wageToken;
    ChainlanceBidToken public bidToken;
    uint256 public auctionCount;
    mapping(uint256 => Auction) public auctions;
    uint256 public constant SERVICE_CHARGE_PERCENT = 10;

    event AuctionCreated(uint256 indexed auctionId, uint256 wage, uint256 endAuction);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 bid);
    event AuctionEnded(uint256 indexed auctionId, address highestBidder, uint256 highestBid, uint256 secondHighestBid);

    constructor(address _wageToken, address _bidToken) Ownable(msg.sender) {
        wageToken = ChainlanceWageToken(_wageToken);
        bidToken = ChainlanceBidToken(_bidToken);
    }

    function createAuction(uint256 _wage, uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration should be greater than zero");

        auctionCount++;
        Auction storage auction = auctions[auctionCount];
        auction.creator = payable(msg.sender);
        auction.wage = _wage;
        auction.endAuction = block.timestamp + _duration;
        auction.settled = false;

        emit AuctionCreated(auctionCount, _wage, auction.endAuction);
    }

    function bid(uint256 _auctionId, uint256 _amount) external {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endAuction, "Auction ended");
        require(_amount > 0, "Bid amount should be greater than zero");

        bidToken.transferFrom(msg.sender, address(this), _amount);

        if (auction.bids[msg.sender] == 0) {
            auction.bidders.push(msg.sender);
        }

        auction.bids[msg.sender] += _amount;

        if (_amount > auction.highestBid) {
            auction.secondHighestBid = auction.highestBid;
            auction.highestBid = _amount;
            auction.highestBidder = msg.sender;
        } else if (_amount > auction.secondHighestBid) {
            auction.secondHighestBid = _amount;
        }

        emit BidPlaced(_auctionId, msg.sender, _amount);
    }

    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endAuction, "Auction not yet ended");
        require(!auction.settled, "Auction already settled");

        auction.settled = true;
        uint256 serviceCharge;

        for (uint256 i = 0; i < auction.bidders.length; i++) {
            address bidder = auction.bidders[i];
            if (bidder != auction.highestBidder) {
                uint256 bidAmount = auction.bids[bidder];
                serviceCharge = (bidAmount * SERVICE_CHARGE_PERCENT) / 100;
                bidToken.transfer(bidder, bidAmount - serviceCharge);
                bidToken.burn(serviceCharge);
            }
        }

        uint256 winningBid = auction.secondHighestBid;
        auction.bids[auction.highestBidder] -= winningBid;

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid, auction.secondHighestBid);
    }
}
