// contracts/OceanToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract LanceToken is ERC20Capped, ERC20Burnable, ERC20Votes {
    address payable public owner;
    address public contract_ = address(this);

    constructor
    () ERC20("LanceToken", "LNC") ERC20Capped(70000000 * (10 ** decimals())) ERC20Permit("LanceToken") {
        owner = payable(msg.sender);
    }


    function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Votes, ERC20) {
    super._afterTokenTransfer(from, to, amount);
  }

    function _mint(address to, uint256 amount) internal override(ERC20Votes, ERC20, ERC20Capped) {
    super._mint(to, amount);
  }

   function _burn(address account, uint256 amount) internal override(ERC20Votes, ERC20) {
    super._burn(account, amount);
  }

    //For debugging
    function pay(address to, uint value) public {
        _mint(payable(to), value);
    }
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
}