// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

contract AlgorithmicStablecoin is ERC20, Ownable {
    IPriceOracle public priceOracle;
    uint256 public targetPrice; // e.g., 1e18 = $1.00 with 18 decimals
    uint256 public adjustmentFactor; // basis points adjustment for mint/burn

    event PriceOracleUpdated(address indexed oracle);
    event TargetPriceUpdated(uint256 newTargetPrice);
    event AdjustmentFactorUpdated(uint256 newAdjustmentFactor);
    event SupplyAdjusted(int256 amount);

    // Default values - change these as needed
    address constant DEFAULT_ORACLE = 0x0000000000000000000000000000000000000000;
    uint256 constant DEFAULT_TARGET_PRICE = 1e18; // $1.00 with 18 decimals
    uint256 constant DEFAULT_ADJUSTMENT_FACTOR = 100; // 1%

    constructor()
        ERC20("Algorithmic Stablecoin", "ASTBL")
        Ownable(msg.sender)
    {
        priceOracle = IPriceOracle(DEFAULT_ORACLE);
        targetPrice = DEFAULT_TARGET_PRICE;
        adjustmentFactor = DEFAULT_ADJUSTMENT_FACTOR;
    }

    // Optional initializer to set oracle/address if defaults were zero address
    function initialize(
        address oracleAddress_,
        uint256 targetPrice_,
        uint256 adjustmentFactor_
    ) external onlyOwner {
        require(address(priceOracle) == address(0), "Already initialized");
        priceOracle = IPriceOracle(oracleAddress_);
        targetPrice = targetPrice_;
        adjustmentFactor = adjustmentFactor_;
    }

    function updatePriceOracle(address newOracle) external onlyOwner {
        priceOracle = IPriceOracle(newOracle);
        emit PriceOracleUpdated(newOracle);
    }

    function updateTargetPrice(uint256 newTargetPrice) external onlyOwner {
        targetPrice = newTargetPrice;
        emit TargetPriceUpdated(newTargetPrice);
    }

    function updateAdjustmentFactor(uint256 newFactor) external onlyOwner {
        adjustmentFactor = newFactor;
        emit AdjustmentFactorUpdated(newFactor);
    }

    /// @notice User can mint stablecoin by depositing ETH as collateral (simplified)
    function mint() external payable {
        require(msg.value > 0, "Send ETH to mint stablecoin");
        _mint(msg.sender, msg.value);
    }

    /// @notice User burns stablecoin to redeem ETH (simplified)
    function redeem(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice Algorithmic supply adjustment triggered by anyone
    function adjustSupply() external {
        uint256 price = priceOracle.getPrice();
        require(price > 0, "Invalid price");

        if (price > targetPrice) {
            uint256 delta = ((price - targetPrice) * totalSupply() * adjustmentFactor) / (targetPrice * 10000);
            if (delta > 0) {
                _mint(owner(), delta);
                emit SupplyAdjusted(int256(delta));
            }
        } else if (price < targetPrice) {
            uint256 delta = ((targetPrice - price) * totalSupply() * adjustmentFactor) / (targetPrice * 10000);
            if (delta > 0) {
                uint256 burnAmount = delta > totalSupply() ? totalSupply() : delta;
                _burn(owner(), burnAmount);
                emit SupplyAdjusted(-int256(burnAmount));
            }
        }
    }

    receive() external payable {}
}
