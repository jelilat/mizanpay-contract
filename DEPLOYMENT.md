# Deployment Guide

This guide explains how to deploy the MizanPay contracts to different networks.

## Prerequisites

1. **Foundry installed** - Make sure you have Foundry installed and set up
2. **Private key** - Your deployment wallet's private key
3. **RPC URLs** - For the networks you want to deploy to
4. **Environment variables** - Set up your deployment configuration

## Environment Setup

Create a `.env` file in the root directory with the following variables:

```bash
# Private key for deployment (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
MAINNET_RPC_URL=https://mainnet.infura.io/v3/your_project_id

# Optional: Etherscan API key for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Network-Specific Addresses

The deployment script automatically sets the correct addresses based on the network:

### Ethereum Mainnet
- **USDC**: `0xA0b86a33E6441b8c4C8C0C8C0C8C0C8C0C8C0C8C` (Replace with actual USDC address)
- **ETH/USD Price Feed**: `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419`
- **Relayer**: Set your relayer address

### Sepolia Testnet
- **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **ETH/USD Price Feed**: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- **Relayer**: Set your relayer address

### Local Development (Anvil)
- **USDC**: Mock address (set to zero address)
- **ETH/USD Price Feed**: Mock address (set to zero address)
- **Relayer**: Mock address (set to zero address)

## Deployment Commands

### Local Development
```bash
# Start local Anvil node
anvil

# In another terminal, deploy to local network
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

### Sepolia Testnet
```bash
# Deploy to Sepolia
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Ethereum Mainnet
```bash
# Deploy to mainnet (be careful!)
forge script script/Deploy.s.sol:DeployScript --rpc-url $MAINNET_RPC_URL --broadcast --verify
```

### Using the Shell Script
```bash
# Make the script executable
chmod +x script/deploy.sh

# Deploy to different networks
./script/deploy.sh local
./script/deploy.sh sepolia
./script/deploy.sh mainnet
```

## Deployment Process

The deployment script performs the following steps:

1. **Deploy Mizan Contract** - The main lending pool contract
2. **Deploy BNPL Contract** - The Buy Now Pay Later contract
3. **Set Cross-Contract References** - Link the contracts together
4. **Add Sample Products** - Create test products for BNPL
5. **Save Deployment Info** - Write contract addresses to `deployment.txt`

## Post-Deployment

After deployment, you'll find a `deployment.txt` file with all contract addresses:

```
Mizan Contract: 0x...
BNPL Contract: 0x...
USDC Token: 0x...
ETH/USD Price Feed: 0x...
Relayer: 0x...
Deployer: 0x...
Network ID: 1
```

## Verification

### Contract Verification
If you have an Etherscan API key, contracts will be automatically verified during deployment.

### Manual Verification
You can manually verify contracts on Etherscan using the deployment artifacts in the `out/` directory.

## Testing Deployment

After deployment, you can test the contracts:

1. **Stake tokens** in Mizan
2. **Add products** to BNPL
3. **Create loans** through BNPL
4. **Test repayments** and withdrawals

## Troubleshooting

### Common Issues

1. **Insufficient funds** - Make sure your deployment wallet has enough ETH
2. **Invalid private key** - Ensure your private key is correct and doesn't include the `0x` prefix
3. **RPC errors** - Check your RPC URL and network connectivity
4. **Gas estimation failures** - Try increasing gas limit or checking contract logic

### Getting Help

If you encounter issues:
1. Check the Foundry documentation
2. Review the contract logs for specific error messages
3. Ensure all dependencies are properly installed

## Security Notes

- **Never commit your `.env` file** to version control
- **Use testnets first** before deploying to mainnet
- **Verify all addresses** before deployment
- **Test thoroughly** on local networks before live deployment 