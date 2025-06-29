#!/bin/bash

# Deployment script for MizanPay contracts
# Usage: ./deploy.sh [network] [etherscan_api_key]

set -e

# Default to local network if not specified
NETWORK=${1:-local}
ETHERSCAN_API_KEY=${2:-""}

echo "Deploying to network: $NETWORK"

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY environment variable is not set"
    echo "Please set your private key: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Deploy based on network
case $NETWORK in
    "local")
        echo "Deploying to local Anvil network..."
        forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
        ;;
    "sepolia")
        echo "Deploying to Sepolia testnet..."
        if [ -n "$ETHERSCAN_API_KEY" ]; then
            forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
        else
            forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast
        fi
        ;;
    "mainnet")
        echo "Deploying to Ethereum mainnet..."
        echo "WARNING: This will deploy to mainnet. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            if [ -n "$ETHERSCAN_API_KEY" ]; then
                forge script script/Deploy.s.sol:DeployScript --rpc-url $MAINNET_RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
            else
                forge script script/Deploy.s.sol:DeployScript --rpc-url $MAINNET_RPC_URL --broadcast
            fi
        else
            echo "Deployment cancelled"
            exit 0
        fi
        ;;
    *)
        echo "Unknown network: $NETWORK"
        echo "Supported networks: local, sepolia, mainnet"
        exit 1
        ;;
esac

echo "Deployment completed! Check deployment.txt for contract addresses." 