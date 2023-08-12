// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {PriceConverter} from "./PriceConverter.sol";

error fundme__NotOwner();

contract fundme {
    using PriceConverter for uint256;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    uint256 public constant MINIMUM_USD = 5e18;
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't get enough eth");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function CheaperWithdraw() public OnlyOwner {
        uint256 funderlength = s_funders.length;
        for (uint256 funderindex = 0; funderindex < funderlength; funderindex++) {
            address funder = s_funders[funderindex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    function withdraw() public OnlyOwner {
        for (uint256 funderindex = 0; funderindex < s_funders.length; funderindex++) {
            address funder = s_funders[funderindex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier OnlyOwner() {
        if (msg.sender != i_owner) revert fundme__NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingaddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingaddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
