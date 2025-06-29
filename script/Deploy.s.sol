// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Mizan.sol";
import "../src/BNPLCollateralLoan.sol";

contract DeployScript is Script {
    // Network-specific addresses
    address public usdc;
    address public ethUsdPriceFeed;
    address public relayer;
    
    // Deployed contracts
    Mizan public mizan;
    BNPLCollateralLoan public bnplContract;

    function setUp() public {
        // Set network-specific addresses based on deployment network
        if (block.chainid == 1) {
            // Ethereum Mainnet
            usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Replace with actual USDC address
            ethUsdPriceFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD Chainlink
            relayer = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // relayer address
        } else if (block.chainid == 11155111) {
            // Sepolia Testnet
            usdc = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // USDC on Sepolia
            ethUsdPriceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD Chainlink
            relayer = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // relayer address
        } else if (block.chainid == 43113) {
            // Avalanche Testnet
            usdc = 0x5425890298aed601595a70AB815c96711a31Bc65; // USDC on Avalanche
            ethUsdPriceFeed = 0x86d67c3D38D2bCeE722E601025C25a575021c6EA; // ETH/USD Chainlink
            relayer = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // relayer address
        } else if (block.chainid == 1337) {
            // Localhost
            usdc = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8; // Mock USDC
            ethUsdPriceFeed = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // Mock price feed
            relayer = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // Mock relayer
        }
        else if (block.chainid == 31337) {
            // Anvil/Local
            usdc = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8; // Mock USDC
            ethUsdPriceFeed = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // Mock price feed
            relayer = 0xBC807A82cc5C6dCE270E2262328059f3B7eEaaaf; // Mock relayer
        } else {
            revert("Unsupported network");
        }
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with address:", deployer);
        console.log("Network ID:", block.chainid);
        console.log("USDC Address:", usdc);
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        console.log("Relayer Address:", relayer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy BNPL contract first
        console.log("Deploying BNPL Collateral Loan contract...");
        bnplContract = new BNPLCollateralLoan(usdc, ethUsdPriceFeed);
        console.log("BNPL contract deployed at:", address(bnplContract));

        // Deploy Mizan contract with BNPL address
        console.log("Deploying Mizan contract...");
        mizan = new Mizan(usdc, relayer, address(bnplContract));
        console.log("Mizan deployed at:", address(mizan));

        // Set up cross-contract references
        console.log("Setting up cross-contract references...");
        
        // Set Mizan address in BNPL contract
        bnplContract.updateMizanAddress(address(mizan));
        console.log("Mizan address set in BNPL contract");

        // Add some sample products (optional)
        console.log("Adding sample products...");
        bnplContract.addProduct("Sample Product 1", 0x66fe4806cD41BcD308c9d2f6815AEf6b2e38f9a3);
        bnplContract.addProduct("Sample Product 2", 0x66fe4806cD41BcD308c9d2f6815AEf6b2e38f9a3);
        console.log("Sample products added");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Mizan Contract:", address(mizan));
        console.log("BNPL Contract:", address(bnplContract));
        console.log("USDC Token:", usdc);
        console.log("ETH/USD Price Feed:", ethUsdPriceFeed);
        console.log("Relayer:", relayer);
        console.log("Deployer:", deployer);
        console.log("Network ID:", block.chainid);
        console.log("========================\n");

        console.log("Deployment completed successfully!");
        console.log("Copy the contract addresses above for future reference.");
    }

    // Function to deploy with custom addresses (for testing)
    function runWithCustomAddresses(
        address _usdc,
        address _ethUsdPriceFeed,
        address _relayer
    ) public {
        usdc = _usdc;
        ethUsdPriceFeed = _ethUsdPriceFeed;
        relayer = _relayer;
        
        run();
    }
} 