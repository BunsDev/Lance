// contracts/OceanToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract BidToken is ERC20Capped, ERC20Burnable {
    address payable public owner;
    address public contract_ = address(this);

    constructor(address signer1, address signer2, address signer3) ERC20("ChainlanceBidToken", "CBT") ERC20Capped(70000000 * (10 ** decimals())) {
        owner = payable(msg.sender);
        _mint(payable (signer1), 30);
        _mint(payable(signer2), 10);
        _mint(payable(signer3), 20);
    }
    function _update(address from, address to, uint value) internal virtual  override(ERC20Capped, ERC20) {
        super._update(from, to, value);
    }

    function pay(address to, uint value) public {
        _mint(payable(to), value);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
}