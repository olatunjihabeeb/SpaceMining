# SpaceMining 🚀

**SpaceMining** is a synthetic assets smart contract providing asteroid mining and space resource extraction exposure on the Stacks blockchain. Users can stake STX tokens to participate in virtual space mining operations and earn rewards based on different asteroid mining pools.

## Overview

SpaceMining allows users to:
- Stake STX tokens in specialized mining pools representing different space resources
- Receive synthetic mining tokens (SMT) representing their stake
- Earn rewards based on mining pool performance and resource type multipliers
- Trade exposure to future space economy without actual space mining operations

## Features

### 🎯 Core Features
- **SIP-010 Compliant Token**: Fully compatible with Stacks token standards
- **Multiple Mining Pools**: Support for different space resource types
- **Dynamic Rewards System**: Block-based rewards with configurable rates
- **Synthetic Asset Exposure**: Get exposure to space mining without operational risks
- **Flexible Staking**: Stake and unstake with automatic reward claiming

### 🪨 Resource Types
- **Platinum** (Type 1): Premium space metal with high value
- **Gold** (Type 2): Traditional precious metal mining
- **Rare Earth** (Type 3): Critical elements for technology
- **Water** (Type 4): Essential resource for space operations

### 💰 Economic Model
- **Base Reward Rate**: 0.01% per block (configurable)
- **Pool Multipliers**: Each pool has unique reward multipliers
- **Automatic Compounding**: Rewards can be claimed at any time
- **Fair Distribution**: Rewards based on stake amount and time

## Technical Specifications

### Blockchain
- **Platform**: Stacks
- **Language**: Clarity
- **Version**: 2.5
- **Token Standard**: SIP-010

### Smart Contract Architecture
- **Main Contract**: `SpaceMining.clar`
- **Token Symbol**: SMT (SpaceMining Token)
- **Decimals**: 6
- **Supply**: Dynamic (minted on stake, burned on unstake)

### Data Structures
- **Mining Pools**: Pool metadata, staking totals, and multipliers
- **User Stakes**: Individual user positions per pool
- **User Totals**: Aggregate user statistics
- **Resource Prices**: Synthetic pricing for space resources

## Installation

### Prerequisites
- Node.js (v16 or higher)
- Clarinet CLI
- Stacks wallet

### Setup
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd SpaceMining
   ```

2. **Install dependencies**:
   ```bash
   cd SpaceMining_contract
   npm install
   ```

3. **Run tests**:
   ```bash
   npm test
   ```

4. **Watch mode for development**:
   ```bash
   npm run test:watch
   ```

## Usage Examples

### Staking in a Mining Pool
```clarity
;; Stake 1000 microSTX in pool 1 (Platinum mining)
(contract-call? .SpaceMining stake-in-pool u1 u1000000)
```

### Claiming Rewards
```clarity
;; Claim accumulated rewards from pool 1
(contract-call? .SpaceMining claim-rewards u1)
```

### Unstaking
```clarity
;; Unstake 500 microSTX from pool 1
(contract-call? .SpaceMining unstake-from-pool u1 u500000)
```

### Checking Pool Information
```clarity
;; Get mining pool details
(contract-call? .SpaceMining get-mining-pool u1)
```

### Token Operations (SIP-010)
```clarity
;; Transfer SMT tokens
(contract-call? .SpaceMining transfer u1000000 tx-sender 'SP1234...)

;; Check token balance
(contract-call? .SpaceMining get-balance 'SP1234...)
```

## Contract Functions Documentation

### Public Functions

#### Core Staking Functions
- **`stake-in-pool(pool-id, amount)`**: Stake STX in a specific mining pool
- **`claim-rewards(pool-id)`**: Claim accumulated mining rewards
- **`unstake-from-pool(pool-id, amount)`**: Unstake STX and burn SMT tokens

#### SIP-010 Token Functions
- **`transfer(amount, from, to, memo)`**: Transfer SMT tokens
- **`get-balance(who)`**: Get token balance for an address
- **`get-total-supply()`**: Get total SMT token supply
- **`get-name()`**: Returns "SpaceMining Token"
- **`get-symbol()`**: Returns "SMT"
- **`get-decimals()`**: Returns 6

#### Admin Functions (Owner Only)
- **`create-mining-pool(name, resource-type, reward-multiplier)`**: Create new mining pool
- **`set-mining-active(active)`**: Enable/disable mining globally
- **`set-reward-rate(new-rate)`**: Update base reward rate (max 10% per block)
- **`update-resource-price(resource-type, price)`**: Set synthetic resource prices
- **`toggle-pool-status(pool-id)`**: Enable/disable specific pools

### Read-Only Functions
- **`get-mining-pool(pool-id)`**: Get pool information
- **`get-user-stake(user, pool-id)`**: Get user's stake in specific pool
- **`get-user-totals(user)`**: Get user's total stakes and rewards
- **`get-total-mining-pools()`**: Get total number of pools
- **`get-total-staked()`**: Get total STX staked across all pools
- **`calculate-pending-rewards(user, pool-id)`**: Calculate claimable rewards

### Constants
- **Resource Types**: PLATINUM (1), GOLD (2), RARE-EARTH (3), WATER (4)
- **Default Prices**: Platinum: 1 STX, Gold: 0.8 STX, Rare Earth: 1.5 STX, Water: 0.1 STX

## Deployment Guide

### Local Development
1. **Start Clarinet console**:
   ```bash
   clarinet console
   ```

2. **Deploy contract**:
   ```clarity
   ::deploy_contracts
   ```

### Testnet Deployment
1. **Configure settings**:
   Edit `settings/Testnet.toml` with your configuration

2. **Deploy using Clarinet**:
   ```bash
   clarinet deployments apply --network testnet
   ```

### Mainnet Deployment
1. **Review security settings**:
   Ensure all admin functions are properly configured

2. **Deploy with proper keys**:
   ```bash
   clarinet deployments apply --network mainnet
   ```

## Security Notes

### ⚠️ Important Security Considerations

1. **Admin Controls**: Contract owner has significant control over:
   - Creating new mining pools
   - Setting reward rates (capped at 10% per block)
   - Updating resource prices
   - Enabling/disabling pools and mining

2. **Economic Risks**:
   - Rewards are paid from the contract's STX balance
   - High reward rates could lead to economic imbalances
   - Pool multipliers affect reward distribution

3. **Smart Contract Risks**:
   - Contract holds user STX funds
   - No emergency pause mechanism
   - Permanent token burns on unstaking

### 🔒 Best Practices

1. **For Users**:
   - Understand reward calculations before staking
   - Monitor pool status and multipliers
   - Claim rewards regularly to minimize exposure

2. **For Administrators**:
   - Set conservative reward rates initially
   - Monitor contract STX balance for reward solvency
   - Regularly audit pool performance and user activity

3. **For Integration**:
   - Implement proper error handling for all contract calls
   - Validate user inputs before contract interactions
   - Use read-only functions for data queries

### 📋 Audit Recommendations

- Formal security audit recommended before mainnet deployment
- Stress testing with various reward rates and user behaviors
- Economic modeling to ensure sustainable reward distribution
- Consider implementing emergency controls or governance mechanisms

## Development

### Project Structure
```
SpaceMining_contract/
├── contracts/
│   └── SpaceMining.clar     # Main smart contract
├── tests/                   # Unit tests
├── settings/               # Network configurations
├── Clarinet.toml          # Project configuration
└── package.json           # Dependencies and scripts
```

### Testing
The project uses Vitest with Clarinet SDK for comprehensive testing:
- Unit tests for all contract functions
- Integration tests for complete user flows
- Coverage reporting for code quality

### Contributing
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please open an issue on the project repository.

---

**Disclaimer**: SpaceMining is an experimental DeFi protocol. Cryptocurrency investments carry inherent risks. Users should understand the smart contract mechanics and associated risks before participating.