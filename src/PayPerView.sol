// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
error PayPerView__NotOwner();

contract PayPerView {
    using PriceConverter for uint256;

    string private s_contentHash; // e.g. IPFS link
    uint256 public constant MINIMUM_USD = 5 * 1e18;
    address private immutable i_owner;
    address[] private s_payers;
    mapping(address => uint256) private s_addressToAmountPaid;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert PayPerView__NotOwner();
        _;
    }

    // Constructor

    constructor (address priceFeed, string memory contentHash) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
        s_contentHash = contentHash;
    }

    // Content-view Function

    function viewContentHash() public view returns (string memory) {
    require(s_addressToAmountPaid[msg.sender] > 0, "Access denied: Pay first");
    return s_contentHash;
    }

    // Paying Function
    
    function payToView() public payable {
        require (
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You don't have Enough ETH!"
        );
        s_addressToAmountPaid[msg.sender] += msg.value;
        s_payers.push(msg.sender);
    }

    // Withdraw Function

    function withdraw() public onlyOwner {
        for (uint256 f_index = 0; f_index < s_payers.length; f_index++) {
            address payer = s_payers[f_index];
            s_addressToAmountPaid[payer] = 0;
        }

        s_payers = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success, "Withdraw Unsuccessful");
    }

    // Cheaper Withdraw Function

    function cheaperWithdraw() public onlyOwner {
        address[] memory payers = s_payers;
        for (uint256 f_index = 0; f_index < payers.length; f_index++) {
            address payer = payers[f_index];
            s_addressToAmountPaid[payer] = 0;
        }
        s_payers = new address[](0);

        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success, "Withdraw Unsuccessful");
    }

    // View Functions

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPayer(uint256 index) public view returns (address) {
        return s_payers[index];
    }

    function getAddressToAmountPaid(address payer) public view returns (uint256) {
        return s_addressToAmountPaid[payer];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
}
