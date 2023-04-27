//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IMinterController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DotSHMMarketplace {
    IMinterController private _minterController;
    address private _owner;
    uint256 private _salePrice;
    mapping(address => uint256) private _referralPercentages;
    mapping(address => bool) private _registeredDomainHolders;
    event DomainPurchased(
        address indexed buyer,
        string indexed label,
        uint256 salePrice
    );

    constructor(IMinterController minterController) {
        _minterController = minterController;
        _owner = msg.sender;
        _salePrice = 1 ether;
    }

    function setSalePrice(uint256 salePrice) external onlyOwner {
        require(salePrice > 0, "Sale price must be greater than 0");
        _salePrice = salePrice;
    }

    function setReferralPercentage(
        address referrer,
        uint256 percentage
    ) external onlyOwner {
        require(
            _registeredDomainHolders[referrer],
            "Referrer must be a registered domain holder"
        );
        require(percentage <= 20, "Percentage cannot exceed 20");
        _referralPercentages[referrer] = percentage;
    }

    function registerDomainHolder(address domainHolder) internal {
        _registeredDomainHolders[domainHolder] = true;
    }

    function purchaseDomainWithReferral(
        address referrer,
        string calldata label
    ) external payable {
        require(
            _registeredDomainHolders[referrer],
            "Only registered domain holders can purchase domains"
        );
        require(msg.value >= _salePrice, "Insufficient funds");

        // Calculate the referral bonus

        uint256 referralPercentage = _referralPercentages[referrer];
        if (referralPercentage == 0) {
            referralPercentage = 10;
        }
        uint256 referralBonus = (msg.value * referralPercentage) / 100;
        uint256 payment = msg.value - referralBonus;

        // Mint the domain token
        _minterController.mintURI(msg.sender, label);

        // Pay the referral bonus
        if (referralBonus > 0) {
            (bool s, ) = payable(referrer).call{value: referralBonus}("");
            require(s, "eth transfer failed");
        }

        // Pay the seller
        (bool success, ) = payable(_owner).call{value: payment}("");
        require(success, "eth transfer failed");
        registerDomainHolder(msg.sender);
        emit DomainPurchased(msg.sender, label, _salePrice);
    }

    function purchaseDomainWithoutReferral(
        string calldata label
    ) external payable {
        require(msg.value >= _salePrice, "Insufficient funds");

        // Mint the domain token
        _minterController.mintURI(msg.sender, label);

        // Pay the seller
        (bool success, ) = payable(_owner).call{value: msg.value}("");
        require(success, "eth transfer failed");
        registerDomainHolder(msg.sender);
        emit DomainPurchased(msg.sender, label, _salePrice);
    }

    function getDomainForOwner(
        address account,
        string calldata label
    ) external onlyOwner {
        // account: address for which the domain should be assigned free of cost
        _minterController.mintURI(account, label);
        registerDomainHolder(account);
        emit DomainPurchased(account, label, 0);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No eth in the contract");
        payable(_owner).transfer(address(this).balance);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not authorized");
        _;
    }

    function withdrawERC20(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");

        IERC20(tokenAddress).transfer(_owner, balance);
    }
}
