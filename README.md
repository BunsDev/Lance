# Project Name: Chainlance Smart Contracts

This repository contains smart contracts for the Chainlance project, including token contracts, blind auction contracts, evaluator contracts, and governance contracts.

## Table of Contents

- [Contracts](#contracts)
  - [LanceToken.sol](#lancetokensol)
  - [BlindAuction.sol](#blindauctionsol)
  - [GetBlindedBid.sol](#getblindedbidsol)
  - [EvaluatorContract.sol](#evaluatorcontractsol)
  - [TimeLock.sol](#timelocksol)
  - [GovernorContract.sol](#governorcontractsol)
- [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Contracts

### BidToken.sol

The `BidToken` contract is an ERC20 token with a capped supply and burnable functionality.

```solidity
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract BidToken is ERC20Capped, ERC20Burnable {
    address payable public owner;
    address public contract_ = address(this);

    constructor() ERC20("ChainlanceBidToken", "CBT") ERC20Capped(70000000 * (10 ** decimals())) {
        owner = payable(msg.sender);
        _mint(payable (msg.sender), 70000000);
    }

    function pay(address to, uint value) public {
        _mint(payable(to), value);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}
```

### LanceToken.sol

The `LanceToken` contract is an ERC20 token with capped supply, burnable, and voting functionalities.

```solidity
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract LanceToken is ERC20Capped, ERC20Burnable, ERC20Votes {
    address payable public owner;
    address public contract_ = address(this);

    constructor() ERC20("LanceToken", "LNC") ERC20Capped(70000000 * (10 ** decimals())) ERC20Permit("LanceToken") {
        owner = payable(msg.sender);
    }

    function pay(address to, uint value) public {
        _mint(payable(to), value);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Votes, ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes, ERC20, ERC20Capped) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Votes, ERC20) {
        super._burn(account, amount);
    }
}
```

### BlindAuction.sol

The `BlindAuction` contract allows for blind bidding on a job with Lance tokens.

```solidity
// See full contract from the provided code above...
```

### GetBlindedBid.sol

This is a utility contract for generating blinded bids.

```solidity
pragma solidity ^0.8.4;

contract GetBlindedBid {
    uint256[] array = [0,1,2,3,4,5,6,7,8];
    
    function getBlindedBid(uint value, bytes32 secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, secret));
    }

    // Other utility functions...
}
```

### EvaluatorContract.sol

The `EvaluatorContract` manages evaluators who stake Lance tokens to participate in evaluating jobs.

```solidity
// See full contract from provided code...
```

### TimeLock.sol

The `TimeLock` contract from OpenZeppelin for timelock-controlled contract modifications.

```solidity
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
   // Constructor and inherited functionality...
}
```

### GovernorContract.sol

The `GovernorContract` for on-chain governance using Lance tokens, including proposal and voting functionalities, built using OpenZeppelin's Governor framework.

```solidity
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";

contract GovernorContract is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
  // Constructor and inherited functionality...
}
```

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/)
- [Hardhat](https://hardhat.org/)

### Installation

1. Clone the repository:
   
```sh
git clone https://github.com/your-repo/chainlance.git
cd chainlance
```

2. Install dependencies:

```sh
npm install
```

### Running Tests

To run the tests, use the following command:

```sh
npx hardhat test
```

## Deployment

### Deploying Contracts

To deploy the contracts, use the Hardhat deployment scripts and configuration. Example:

```sh
npx hardhat run scripts/deploy.js --network yourNetwork
```

### Configuration

Configure the deployment settings in `hardhat.config.js` and deployment scripts in the `scripts` folder.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue if you have any suggestions or improvements.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
