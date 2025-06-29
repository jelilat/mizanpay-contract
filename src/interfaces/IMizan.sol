// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoan.sol";

interface IMizan {
    // Events
    event Staked(address indexed user, uint256 amount, uint256 depositTokens);
    event Unstaked(address indexed user, uint256 amount, uint256 depositTokens);

    // Token interfaces
    function underlyingToken() external view returns (IERC20);
    function depositToken() external view returns (address);
    function loanToken() external view returns (address);

    // Flash loan state
    function relayer() external view returns (address);
    function profitSharePercentage() external view returns (uint256);
    function usedNonces(bytes32) external view returns (bool);

    // Pool accounting
    function totalLiquidity() external view returns (uint256);
    function totalLiquidityTokens() external view returns (uint256);
    function LOAN_RESERVE_RATIO() external view returns (uint256);

    // BNPL integration
    function bnplContract() external view returns (address);
    function bnplLoans() external view returns (uint256);
    function bnplRevenue() external view returns (uint256);

    // Core functions
    function stake(uint256 amount) external;
    function unstake(uint256 depositTokenAmount) external;
    function requestLoan(uint256 amount) external;
    function repayLoan(uint256 amount) external;

    // Flash loan functions
    function requestFlashLoan(
        address _loanToken,
        uint256 loanAmount,
        IFlashLoan.FlashLoanMeta calldata meta,
        bytes calldata signature
    ) external;

    // Pure functions for hashing and encoding
    function hashProfitMetadata(
        IFlashLoan.ProfitMetadata[] calldata data
    ) external pure returns (bytes32);

    function hashFlashLoanRequest(
        address loanToken,
        uint256 loanAmount,
        uint256 expiry,
        bytes32 nonce,
        bytes32 profitHash
    ) external pure returns (bytes32);

    // BNPL functions
    function requestBnplLoan(uint256 productId) external;
    function repayBnplLoan(uint256 amount) external;

    // Admin functions
    function updateRelayer(address _relayer) external;
    function updateProfitSharePercentage(uint256 _percentage) external;

    // View functions
    function getStakedAmount(address user) external view returns (uint256);
    function getBorrowedAmount(address user) external view returns (uint256);
    function getPoolStats()
        external
        view
        returns (
            uint256 _totalLiquidity,
            uint256 _availableLoanReserve,
            uint256 _totalLiquidityTokens
        );

    // Receive function
    receive() external payable;
} 