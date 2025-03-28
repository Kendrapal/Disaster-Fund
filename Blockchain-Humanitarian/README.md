# Decentralized Disaster Relief Protocol

## Overview

The Decentralized Disaster Relief Protocol is a transparent and fair blockchain-based system for managing disaster relief funds. Leveraging the power of smart contracts, this protocol enables secure donations, victim registration, verification, and fund allocation with community governance.

## Key Features

### 1. Donation Management
- Minimum donation threshold of 100,000 STX
- Donors receive NFT tokens representing their contribution
- Voting power proportional to donation amount
- Transparent tracking of total protocol funds

### 2. Victim Registration
- Secure and encrypted victim information submission
- Multi-step verification process
- Privacy-preserving data handling
- Damage level assessment

### 3. Oracle-Based Verification
- Authorized verification oracles
- Threshold-based victim verification
- Decentralized verification mechanism

### 4. Proposal and Voting System
- Community-driven relief fund allocation
- Voting power based on donation contributions
- Transparent proposal creation and voting

## Smart Contract Components

### Main Mappings
- `protocol-donors`: Tracks donor contributions and voting power
- `disaster-records`: Stores information about registered disasters
- `relief-allocation-proposals`: Manages fund allocation proposals
- `victim-registration-records`: Handles victim registration details

### Key Functions

#### Donor Functions
- `contribute-to-relief-fund()`: Make a donation and receive an NFT
- `transfer-contribution-token()`: Transfer donation NFT

#### Disaster Management
- `register-new-disaster()`: Create a new disaster record
- `update-disaster-severity-level()`: Modify disaster severity

#### Victim Support
- `register-disaster-victim()`: Submit victim information
- `verify-disaster-victim()`: Oracle-based victim verification

#### Governance
- `create-relief-allocation-proposal()`: Propose fund allocation
- `vote-on-relief-proposal()`: Vote on relief proposals

## Access Control
- Protocol admin manages critical functions
- Authorized verification oracles for victim validation
- Role-based access for sensitive operations

## Error Handling
Comprehensive error codes for various scenarios:
- Unauthorized access
- Insufficient funds
- Invalid donation amounts
- Proposal execution status

## Technical Details
- Developed on Stacks blockchain
- Uses NFT for donation tracking
- Supports encrypted personal data
- Implements transparent fund management

## Security Considerations
- Multi-step verification process
- Encrypted victim data
- Role-based access control
- Threshold-based decision making

## Getting Started

### Prerequisites
- Stacks wallet
- Basic understanding of blockchain donations
- Minimum donation of 100,000 STX

### Contribution Process
1. Connect Stacks wallet
3. Receive donation NFT
4. Optionally participate in governance

## Future Roadmap
- Expand verification oracle network
- Implement more granular voting mechanisms
- Enhanced privacy features
- Cross-chain donation support