// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.28;
// 2. Imports

import {AggregatorV3Interface} from
    "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";
import {console2} from "forge-std/console2.sol";

// 3. Interfaces, Libraries, Contracts

/**
 * @title A sample Funding Contract
 * @author Elene Urushadze
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    error FundMe__NotOwner();
    error FundMe__NotEnoughEth();

    uint256 public constant MINIMUM_USD = 5e18; // constant - gas effiient  // test
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders; // private variables are more gas efficient than public ones, so we make variables private and write getter functions for tests
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner; //  immutable - gas efficient. variables that we set one time but outside the same line that they are declared, we can mark as immutable

    constructor(address priceFeed) {
        i_owner = msg.sender; // test
        console2.log("message sender: ", msg.sender);
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughEth(); // test
        }
        s_addressToAmountFunded[msg.sender] += msg.value; // test
        s_funders.push(msg.sender); // test
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); // we are using new keyword to reset the funders array to a blank new blank address array, 0 means to start off at a length of zero
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        // test
        uint256 funderLength = s_funders.length; // bc reading from memory costs 3 gas and reading from storage costs 100 gas. by this method we dont have to read from storage for looping trough the length of funders
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    function getPrice() public view returns (uint256) {
        // address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // abi:
        (, int256 price,,,) = s_priceFeed.latestRoundData();
        return uint256(price * 1e10); // type casting
    }

    modifier onlyOwner() {
        // we dont give it a visibility
        // require(msg.sender == i_owner, "Only owner");
        // _; // require first, then execute the code inside the function
        if (msg.sender != i_owner) {
            // more gas efficient than require
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        // as long as there is no data // blank transact
        fund();
    }

    fallback() external payable {
        // in transact: 0x00
        fund();
    }

    // getter functions

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddresToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
