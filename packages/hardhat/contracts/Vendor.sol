// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    /////////////////
    /// Errors //////
    /////////////////
    error InvalidEthAmount();
    error InsufficientVendorTokenBalance(uint256 available, uint256 required);
    error EthTransferFailed(address to, uint256 amount);
    error InvalidTokenAmount();
    error InsufficientVendorEthBalance(uint256 available, uint256 required);

    //////////////////////
    /// State Variables //
    //////////////////////
    YourToken public immutable yourToken;
    uint256 public constant tokensPerEth = 100;

    ////////////////
    /// Events /////
    ////////////////
    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address indexed seller, uint256 amountOfTokens, uint256 amountOfETH);

    ///////////////////
    /// Constructor ///
    ///////////////////
    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    ///////////////////
    /// Functions /////
    ///////////////////
    function buyTokens() external payable {
        if (msg.value == 0) revert InvalidEthAmount();

        uint256 amountOfTokens = msg.value * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        if (vendorBalance < amountOfTokens) {
            revert InsufficientVendorTokenBalance(vendorBalance, amountOfTokens);
        }

        bool sent = yourToken.transfer(msg.sender, amountOfTokens);
        require(sent, "Token transfer failed");

        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = owner().call{value: amount}("");
        if (!sent) revert EthTransferFailed(owner(), amount);
    }

    function sellTokens(uint256 amount) public {
        if (amount == 0) revert InvalidTokenAmount();

        uint256 ethAmount = amount / tokensPerEth;
        uint256 vendorEthBalance = address(this).balance;
        if (vendorEthBalance < ethAmount) {
            revert InsufficientVendorEthBalance(vendorEthBalance, ethAmount);
        }

        bool transferred = yourToken.transferFrom(msg.sender, address(this), amount);
        require(transferred, "Token transfer failed");

        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        if (!sent) revert EthTransferFailed(msg.sender, ethAmount);

        emit SellTokens(msg.sender, amount, ethAmount);
    }


}