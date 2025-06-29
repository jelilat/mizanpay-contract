// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IFlashLoan {
    struct ProfitMetadata {
        address taker;
        address token; // address(0) represents native ETH
    }

    struct FlashLoanMeta {
        ProfitMetadata[] profits;
        uint256 expiry;
        bytes32 nonce;
    }
} 