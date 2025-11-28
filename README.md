# IPaymentStream - MicroPayment Network
A modular, gas-optimized on-chain micro-payment network supporting real-time streaming payments, usage-based billing, and automated batch settlements

[![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF6943.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A gas-optimized, modular smart contract system for real-time payment streaming and usage-based billing on Ethereum. Built for AI agents, IoT devices, and automated service payments.

## Overview

MicroPayment Network enables continuous, per-second payment streams with on-chain settlement, eliminating the need for manual recurring payments. The system supports both time-based streaming and usage-based billing through a flexible oracle integration.

### Key Features

- **Real-time Payment Streaming** - Per-second fund transfers with dynamic rate adjustment
- **Usage-Based Billing** - Oracle-powered metering for pay-per-use models
- **Batch Settlements** - Gas-efficient bulk withdrawals across multiple streams
- **Role-Based Security** - Granular access control for oracle management
- **Event-Driven Architecture** - Complete indexing support for off-chain monitoring

## Architecture

The system consists of three core contracts:

**StreamManager** - Handles payment stream lifecycle management including creation, withdrawals, and rate updates.

**UsageOracle** - Provides usage-based billing capabilities with authorized oracle nodes recording consumption metrics.

**BatchSettler** - Optimizes gas costs through bulk settlement operations across multiple payment streams.

## Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) toolkit
- Node.js 16 or higher
- Git

### Setup

```bash
git clone https://github.com/your-org/micro-payment-network.git
cd micro-payment-network
forge install
forge build
```

## Quick Start

### Opening a Payment Stream

```solidity
// Deploy StreamManager
StreamManager streamManager = new StreamManager();

// Open stream paying 0.1 ETH per day
uint256 streamId = streamManager.openStream{value: 1 ether}(
    payeeAddress,
    115740740740740, // 0.1 ETH per day in wei/second
    1 ether           // Initial deposit
);
```

### Withdrawing Funds

```solidity
// After time has passed, payee can withdraw
uint256 withdrawn = streamManager.withdrawAvailable(streamId);
```

### Usage-Based Billing

```solidity
// Deploy oracle
UsageOracle oracle = new UsageOracle();

// Set rate per usage unit
oracle.setRateForUsage(streamId, 0.001 ether);

// Oracle records usage
oracle.recordUsage(streamId, 100); // 100 units consumed
```

## API Documentation

### StreamManager

#### `openStream(address payee, uint256 ratePerSecond, uint256 depositAmount) payable returns (uint256)`

Creates a new payment stream.

**Parameters:**
- `payee` - Recipient address for the payment stream
- `ratePerSecond` - Payment rate in wei per second
- `depositAmount` - Initial deposit amount in wei

**Returns:** Stream ID for the created payment stream

**Requirements:**
- `msg.value` must equal `depositAmount`
- `ratePerSecond` must be greater than zero
- `payee` cannot be zero address

#### `withdrawAvailable(uint256 streamId) returns (uint256)`

Withdraws accumulated funds from an active stream.

**Parameters:**
- `streamId` - ID of the stream to withdraw from

**Returns:** Amount withdrawn in wei

**Requirements:**
- Caller must be the stream payee
- Stream must be active

#### `updateRate(uint256 streamId, uint256 newRatePerSecond)`

Updates the payment rate for an existing stream.

**Parameters:**
- `streamId` - ID of the stream to update
- `newRatePerSecond` - New payment rate in wei per second

**Requirements:**
- Caller must be the stream payer
- Stream must be active
- New rate must be greater than zero

#### `closeStream(uint256 streamId)`

Closes a payment stream and returns remaining balance to payer.

**Parameters:**
- `streamId` - ID of the stream to close

**Requirements:**
- Caller must be the stream payer
- Stream must be active

### UsageOracle

#### `recordUsage(uint256 streamId, uint256 units)`

Records usage units for a stream (oracle nodes only).

**Parameters:**
- `streamId` - ID of the stream
- `units` - Number of usage units consumed

**Requirements:**
- Caller must have oracle role
- Stream must exist

#### `setRateForUsage(uint256 streamId, uint256 ratePerUnit)`

Sets the billing rate per usage unit.

**Parameters:**
- `streamId` - ID of the stream
- `ratePerUnit` - Rate in wei per unit

**Requirements:**
- Caller must be stream payer

### BatchSettler

#### `batchSettle(uint256[] calldata streamIds) returns (uint256)`

Settles multiple streams in a single transaction.

**Parameters:**
- `streamIds` - Array of stream IDs to settle

**Returns:** Total amount withdrawn across all streams

## Testing

The project includes a comprehensive test suite covering all core functionality.

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run with detailed output
forge test -vvv

# Generate coverage report
forge coverage
```

### Test Coverage

- Stream lifecycle management
- Withdrawal calculations and edge cases
- Rate updates and validations
- Usage-based billing scenarios
- Batch settlement operations
- Access control and permissions
- Gas optimization verification

## Gas Optimization

The contracts are optimized for minimal gas consumption:

| Operation | Estimated Gas |
|-----------|--------------|
| Open Stream | ~125,000 |
| Withdraw | ~65,000 |
| Update Rate | ~35,000 |
| Record Usage | ~28,000 |
| Batch Settle (per stream) | ~45,000 |

Optimization techniques include packed struct storage, efficient mathematical operations, minimal storage writes, and event-driven data recording.

## Deployment

### Local Deployment

```bash
# Start local node
anvil

# Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Mainnet Deployment

Review deployment checklist before mainnet deployment including security audit completion, comprehensive testing on testnets, gas price optimization, and contract verification preparation.

## Use Cases

### AI Agent Services

Enable AI agents to pay for continuous computational services with real-time streaming payments based on actual usage or time.

### IoT Device Billing

Implement pay-per-use models for IoT devices, sensors, and data providers with automatic settlement based on consumption.

### API Services

Create subscription-free API services where clients pay continuously based on actual usage rather than fixed monthly fees.

### Decentralized Applications

Power DApps with continuous payment flows for services like video streaming, cloud storage, or computational resources.

## Security Considerations

The contracts implement multiple security measures including reentrancy protection, integer overflow protection through Solidity 0.8.x, comprehensive access control, and input validation on all external functions.

### Recommended Practices

- Conduct thorough security audits before mainnet deployment
- Implement monitoring for unusual activity patterns
- Use timelock mechanisms for critical parameter updates
- Maintain emergency pause functionality for critical scenarios
- Regular security reviews as the codebase evolves

## Contributing

Contributions are welcome. Please follow these guidelines:

1. Fork the repository and create a feature branch
2. Write comprehensive tests for new functionality
3. Ensure all tests pass and gas usage remains optimized
4. Follow the Solidity style guide and existing code conventions
5. Submit a pull request with a clear description of changes

## License

This project is licensed under the MIT License. See the LICENSE file for complete details.

## Support

- **Documentation**: [GitHub Wiki](https://github.com/your-org/micro-payment-network/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-org/micro-payment-network/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/micro-payment-network/discussions)

## Acknowledgments

Built with OpenZeppelin contract libraries, Foundry development framework, and contributions from the Ethereum developer community.

---

Built for the decentralized web with a focus on efficiency, security, and usability.
