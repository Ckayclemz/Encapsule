# Encapsule Smart Contract

A blockchain solution for chronologically-secured, encrypted payload storage on the Stacks blockchain.

## Overview

Encapsule is a time-locked data storage smart contract that allows users to store encrypted payloads that can only be retrieved after a specified number of blocks have passed. This creates a trustless time-based access control mechanism on the blockchain.

## Features

- **Time-locked Storage**: Store data that becomes accessible only after a specified block height
- **Encrypted Payloads**: Support for encrypted string data up to 500 UTF-8 characters
- **Access Control**: Only the original creator can retrieve their stored data
- **Sequential Tracking**: Automatic assignment of unique reference numbers for each capsule
- **Metadata Inspection**: Query capsule status and release information

## Contract Functions

### Public Functions

#### `encrypt-capsule`
Creates a new time-locked capsule with encrypted payload.

**Parameters:**
- `payload` (string-utf8 500): The encrypted data to store
- `lockdown-duration` (uint): Number of blocks to lock the data

**Returns:** 
- `(response uint uint)`: Success returns the capsule reference number, failure returns error code

**Usage:**
```clarity
(contract-call? .encapsule encrypt-capsule "encrypted-data-here" u144) ;; Lock for ~24 hours (assuming 10min blocks)
```

#### `decrypt-capsule`
Retrieves the encrypted payload from a matured capsule.

**Parameters:**
- `ref-num` (uint): The capsule reference number

**Returns:**
- `(response (string-utf8 500) uint)`: Success returns the encrypted payload, failure returns error code

**Restrictions:**
- Can only be called by the original creator
- Can only be called after the release block height is reached

**Usage:**
```clarity
(contract-call? .encapsule decrypt-capsule u1)
```

### Read-Only Functions

#### `examine-metadata`
Returns metadata information about a specific capsule.

**Parameters:**
- `ref-num` (uint): The capsule reference number

**Returns:**
- `(response {release-block: uint, retrieved: bool} uint)`

**Restrictions:**
- Can only be called by the original creator

#### `enumerate-capsules`
Returns the total number of capsules created.

**Returns:**
- `(response uint uint)`: The total count of capsules

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `exc-unauthorized` | Caller is not authorized to access this capsule |
| u101 | `exc-duplicate-entry` | Attempting to create a duplicate entry |
| u102 | `exc-missing-record` | Capsule with specified reference number doesn't exist |
| u103 | `exc-premature-access` | Attempting to access capsule before release block |
| u104 | `exc-invalid-duration` | Lockdown duration must be greater than 0 |
| u105 | `exc-operation-failure` | Internal operation failed |

## Usage Examples

### Creating a Time-Locked Message
```clarity
;; Create a capsule that unlocks in 100 blocks
(contract-call? .encapsule encrypt-capsule "My secret message" u100)
;; Returns: (ok u1) - First capsule created
```

### Checking Capsule Status
```clarity
;; Check when capsule #1 will be available
(contract-call? .encapsule examine-metadata u1)
;; Returns: (ok {release-block: u150000, retrieved: false})
```

### Retrieving Unlocked Data
```clarity
;; Retrieve data from capsule #1 (only after release-block)
(contract-call? .encapsule decrypt-capsule u1)
;; Returns: (ok "My secret message")
```

### Getting Total Capsule Count
```clarity
(contract-call? .encapsule enumerate-capsules)
;; Returns: (ok u5) - if 5 capsules have been created
```

## Security Considerations

1. **Encryption**: The contract stores data as provided - ensure client-side encryption before storing sensitive data
2. **Access Control**: Only the original creator can access their capsules
3. **Time Locks**: Data becomes accessible based on block height, not real-world time
4. **Immutability**: Once stored, capsule data cannot be modified or deleted

## Block Time Estimates

On Stacks, blocks are mined approximately every 10 minutes. Use these estimates for planning:

- 1 hour: ~6 blocks
- 1 day: ~144 blocks  
- 1 week: ~1,008 blocks
- 1 month: ~4,320 blocks

## Deployment

Deploy this contract to the Stacks blockchain using Clarinet or your preferred deployment tool. The contract requires no initialization parameters.
