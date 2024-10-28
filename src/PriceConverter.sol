// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AggregatorV3Interface} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // abi:
        (, int256 price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // type casting
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    function getVersion(AggregatorV3Interface priceFeed) public view returns (uint256) {
        return AggregatorV3Interface(priceFeed).version();
    }
}
