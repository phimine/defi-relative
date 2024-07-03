// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error Bank__NotOwner();
error Bank__ERC20TransferError(
    address from,
    address to,
    address token,
    uint256 amount
);
error Bank__ERC721TransferError(
    address from,
    address to,
    address token,
    uint256 tokenId
);

/**
 * @title 储钱罐合约
 * 1. 所有人都可以存钱 ETH
 * 2. 只有合约 owner 才可以取钱
 * 3. 只要取钱，合约就销毁掉 selfdestruct
 * 4。 扩展：支持主币以外的资产：ERC20、ERC721
 * @author Carl Fu
 */
contract Bank {
    // State Variable
    address private immutable owner;

    // Event
    event Deposit(address indexed from, uint256 amount);
    event ERC20Deposit(
        address indexed from,
        address indexed token,
        uint256 amount
    );
    event ERC721Deposit(
        address indexed from,
        address indexed token,
        uint256 tokenId
    );
    event Withdraw(uint256 _amount);
    event WithdrawERC20(address indexed token, uint256 amount);
    event WithdrawERC721(address indexed token, uint256 tokenId);

    // Modifier
    modifier OnlyOwner() {
        if (owner != msg.sender) {
            revert Bank__NotOwner();
        }
        _;
    }

    // Constructor
    constructor() payable {
        owner = msg.sender;
    }

    // receive()
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function depositERC20(address token, uint256 amount) external {
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        // ERC20 token transfer failed
        if (!success) {
            revert Bank__ERC20TransferError(
                msg.sender,
                address(this),
                token,
                amount
            );
        }
        emit ERC20Deposit(msg.sender, token, amount);
    }

    function depositERC721(address token, uint tokenId) external {
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit ERC721Deposit(msg.sender, token, tokenId);
    }

    // Functions
    function withdraw() external OnlyOwner {
        uint256 amount = address(this).balance;
        emit Withdraw(amount);
        selfdestruct(payable(msg.sender));
    }

    function withdrawERC20(address token) external OnlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        bool succcess = IERC20(token).transfer(owner, balance);
        if (!succcess) {
            revert Bank__ERC20TransferError(
                address(this),
                msg.sender,
                token,
                balance
            );
        }
        emit WithdrawERC20(token, balance);
        selfdestruct(payable(msg.sender));
    }

    function withdrawERC721(address token, uint256 tokenId) external OnlyOwner {
        IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
        emit WithdrawERC721(token, tokenId);
        selfdestruct(payable(msg.sender));
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}
