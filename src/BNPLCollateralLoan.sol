// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMizan.sol";

contract BNPLCollateralLoan is Ownable {
    struct Product {
        string name;
        address productAddress;
        uint256 totalEarnings;
        uint256 nextWithdrawDate;
        bool active;
    }

    struct Loan {
        address borrower;
        address collateralToken; // only ETH is supported for now
        uint256 collateralAmount;
        address loanToken; // only USDC is supported for now
        uint256 loanAmount; 
        uint256 productId;
        uint256 disbursedAt;
        uint256 repaidAmount;
        uint256 repaymentPlan; // 0: 30-day lump sum, 1: 4-instalment 60-day
        uint256 nextPaymentDueAt;
        bool repaid;
    }

    mapping(address => bool) public whitelistedTokens;
    mapping(address => address) public priceFeeds;
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userLoans;
    mapping(address => uint256) public outstandingLoans;
    mapping(uint256 => Product) public products;
    uint256 public loanCounter;
    uint256 public productCounter;
    uint256 public platformRevenue;

    address public usdc;
    address public mizan;
    uint256 public constant LTV = 80; // 80% LTV
    uint256 public constant PLATFORM_FEE = 3; // 3% platform fee

    event LoanCreated(uint256 loanId, address borrower, uint256 amount);
    event LoanRepaid(uint256 loanId);
    event CollateralWithdrawn(uint256 loanId);
    event ProductAdded(uint256 productId, string name, address productAddress);
    event ProductRemoved(uint256 productId);
    event ProductEarningsWithdrawn(uint256 productId, uint256 amount);

    constructor(address _usdc, address _ethUsdPriceFeed) Ownable(msg.sender) {
        usdc = _usdc;
        whitelistedTokens[address(0)] = true;
        priceFeeds[address(0)] = _ethUsdPriceFeed;
    }

    function whitelistToken(address token, address priceFeed, bool status) external onlyOwner {
        whitelistedTokens[token] = status;
        priceFeeds[token] = priceFeed;
    }

    function removeWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens[token] = false;
        priceFeeds[token] = address(0);
    }

    function updateMizanAddress(address _mizan) external onlyOwner {
        mizan = _mizan;
    }

    function getPrice(address token) public view returns (uint256) {
        AggregatorV3Interface feed = AggregatorV3Interface(priceFeeds[token]);
        (, int256 answer,,,) = feed.latestRoundData();
        require(answer > 0, "Invalid price");
        return uint256(answer);
    }

    function calculateLoanEligibility(address token, uint256 loanAmountUSD) public view returns (uint256) {
        require(whitelistedTokens[token], "Not accepted");
        uint256 price = getPrice(token); // price in 1e8 (USD per token)
        
        // Calculate required USD value of collateral: loanAmountUSD * 100 / LTV
        uint256 requiredUSDValue = (loanAmountUSD * 100) / LTV;
        
        // Calculate required token amount: requiredUSDValue * 1e8 / price
        uint256 requiredTokenAmount = (requiredUSDValue * 1e8 * 1e18) / price;
        
        return requiredTokenAmount;
    }

    function depositCollateralAndBorrow(uint256 productId, uint256 plan, uint256 loanAmount) external payable {
        // TODO: Replace msg.sender with tx.origin (safely) when adding EIP-7702 support
        require(plan == 0 || plan == 1, "Invalid plan");
        require(productId < productCounter, "Product does not exist");
        require(products[productId].active, "Product inactive");

        uint256 loanEligibility = calculateLoanEligibility(address(0), msg.value); // address(0) for ETH
        require(loanEligibility >= loanAmount, "Loan amount exceeds eligibility");
        
        // Check if user has approved sufficient loan amount
        uint256 outstandingLoan = outstandingLoans[msg.sender];
        require(IERC20(usdc).allowance(msg.sender, address(this)) >= loanAmount + outstandingLoan, "Insufficient allowance");

        Loan storage loan = loans[loanCounter];
        loan.borrower = msg.sender;
        loan.collateralToken = address(0); // ETH
        loan.collateralAmount = msg.value;
        loan.loanToken = usdc;
        loan.loanAmount = loanAmount;
        loan.productId = productId;
        loan.disbursedAt = block.timestamp;
        loan.repaymentPlan = plan;

        outstandingLoan += loanAmount;

        if (plan == 0) {
            loan.nextPaymentDueAt = loan.disbursedAt + 30 days;
        } else {
            loan.nextPaymentDueAt = loan.disbursedAt + 14 days;
            uint256 firstPayment = loan.loanAmount / 4;
            IERC20(usdc).transferFrom(msg.sender, address(this), firstPayment);
            outstandingLoan -= firstPayment;

            loan.repaidAmount = firstPayment;
            uint256 platformFee = (firstPayment * PLATFORM_FEE) / 100;
            platformRevenue += platformFee;
        }

        userLoans[msg.sender].push(loanCounter);
        outstandingLoans[msg.sender] += outstandingLoan;

        // Transfer loan amount to borrower
        IERC20(usdc).transfer(msg.sender, loanAmount);
        
        // Add earnings to product
        products[productId].totalEarnings += loanAmount;

        emit LoanCreated(loanCounter, msg.sender, loanAmount);

        loanCounter++;
    }

    function repayLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        require(!loan.repaid, "Already repaid");
        require(loan.loanAmount - loan.repaidAmount > 0, "Loan fully repaid");
        require(block.timestamp >= loan.nextPaymentDueAt, "Not due yet");

        uint256 amountToRepay;
        if (loan.repaymentPlan == 0) {
            amountToRepay = loan.loanAmount;
        } else {
            amountToRepay = loan.loanAmount / 4;
        }

        IERC20(usdc).transferFrom(loan.borrower, address(this), amountToRepay);
        loan.repaidAmount += amountToRepay;

        if (loan.repaidAmount >= loan.loanAmount) {
            loan.repaid = true;
            emit LoanRepaid(loanId);

            // Send back the collateral
            if (loan.collateralToken == address(0)) {
                (bool success, ) = loan.borrower.call{value: loan.collateralAmount}("");
                require(success, "ETH transfer failed");
            } else {
                IERC20(loan.collateralToken).transfer(loan.borrower, loan.collateralAmount);
            }

            uint256 platformFee = (loan.loanAmount * PLATFORM_FEE) / 100;
            platformRevenue += platformFee; // TODO: Transfer to Mizan's address
        } else {
            loan.nextPaymentDueAt += 14 days;
        }
    }

    function addProduct(string memory name, address productAddress) external onlyOwner {
        require(productAddress != address(0), "Invalid product address");
        
        Product storage product = products[productCounter];
        product.name = name;
        product.productAddress = productAddress;
        product.totalEarnings = 0;
        product.nextWithdrawDate = block.timestamp + 30 days;
        product.active = true;
        
        emit ProductAdded(productCounter, name, productAddress);
        productCounter++;
    }

    function removeProduct(uint256 productId) external onlyOwner {
        require(productId < productCounter, "Product does not exist");
        require(products[productId].active, "Product already inactive");
        
        products[productId].active = false;
        emit ProductRemoved(productId);
    }

    function withdrawProductEarnings(uint256 productId) external {
        require(productId < productCounter, "Product does not exist");
        Product storage product = products[productId];
        require(product.active, "Product inactive");
        require(msg.sender == product.productAddress, "Not product owner");
        require(block.timestamp >= product.nextWithdrawDate, "Too early to withdraw");
        require(product.totalEarnings > 0, "No earnings to withdraw");
        
        uint256 amountToWithdraw = getProductEarnings(productId);
        product.totalEarnings = 0;
        product.nextWithdrawDate = block.timestamp + 30 days;

        if (IERC20(usdc).balanceOf(address(this)) < amountToWithdraw) {
            requestLoanFromMizan(productId);
        } else {
            IERC20(usdc).transfer(product.productAddress, amountToWithdraw);
        }
        

        uint256 platformFee = (amountToWithdraw * PLATFORM_FEE) / 100;
        platformRevenue += platformFee;
        emit ProductEarningsWithdrawn(productId, amountToWithdraw);
    }

    function requestLoanFromMizan(uint256 productId) internal {
        // Request loan from Mizan
        IMizan mizanContract = IMizan(payable(mizan));
        mizanContract.requestBnplLoan(productId);
    }

    function getOutstandingLoan(address user) public view returns (uint256) {
        return outstandingLoans[user];
    }

    function getProductEarnings(uint256 productId) public view returns (uint256) {
        require(productId < productCounter, "Product does not exist");
        uint256 productEarnings = products[productId].totalEarnings;
        return productEarnings - (productEarnings * PLATFORM_FEE) / 100;
    }

    function getProductOwner(uint256 productId) public view returns (address) {
        require(productId < productCounter, "Product does not exist");
        return products[productId].productAddress;
    }
}
