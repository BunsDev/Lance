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
