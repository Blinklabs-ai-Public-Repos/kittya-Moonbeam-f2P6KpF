// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * @title MultisendToken
 * @dev ERC20 token with multisend functionality, pausable operations, and multicall support.
 */
contract MultisendToken is ERC20Pausable, Multicall {
    uint256 private immutable _maxSupply;
    address private immutable _owner;

    /**
     * @dev Constructor to initialize the token with name, symbol, and max supply.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param maxSupply_ The maximum supply of the token.
     */
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) ERC20(name_, symbol_) {
        require(maxSupply_ > 0, "Max supply must be greater than zero");
        _maxSupply = maxSupply_;
        _owner = msg.sender;
        _mint(msg.sender, maxSupply_);
    }

    /**
     * @dev Returns the maximum supply of the token.
     * @return The maximum supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Multisend function to send tokens to multiple recipients in a single transaction.
     * @param recipients An array of recipient addresses.
     * @param amounts An array of amounts to send to each recipient.
     * @return success A boolean indicating whether the operation was successful.
     */
    function multisend(address[] memory recipients, uint256[] memory amounts) public returns (bool success) {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        require(recipients.length > 0, "At least one recipient is required");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        require(balanceOf(msg.sender) >= totalAmount, "Insufficient balance for multisend");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot send to zero address");
            _transfer(msg.sender, recipients[i], amounts[i]);
        }

        return true;
    }

    /**
     * @dev Pauses all token transfers.
     * @notice Can only be called by the contract owner.
     */
    function pause() public {
        require(msg.sender == _owner, "Only the owner can pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * @notice Can only be called by the contract owner.
     */
    function unpause() public {
        require(msg.sender == _owner, "Only the owner can unpause");
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param amount The amount of tokens to be transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // Minting
            require(totalSupply() + amount <= _maxSupply, "Cannot mint more than max supply");
        }
    }
}