// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Error
error EtherWallet__NotOwnerError();
error EtherWallet__SendError();
error EtherWallet__CallError();

/**
 * @title 这一个实战主要是加深大家对 3 个取钱方法的使用。
 * - 任何人都可以发送金额到合约
 * - 只有 owner 可以取款
 * - 3 种取钱方式: transfer/send/call
 * @author Carl Fu
 * @notice
 */
contract EtherWallet {
    // Type Declaration
    // State Variable
    address private immutable i_owner;

    // Event
    event LogAlert(
        string message,
        address indexed from,
        uint256 amount,
        bytes data
    );

    // Modifier
    modifier OnlyOwner() {
        if (msg.sender != i_owner) {
            revert EtherWallet__NotOwnerError();
        }
        _;
    }

    // Constructor
    constructor() {
        i_owner = msg.sender;
    }

    // Functions
    // receive/fallback
    receive() external payable {
        emit LogAlert("Receive", msg.sender, msg.value, "");
    }

    // external
    function withdrawTransfer() external OnlyOwner {
        // owner.transfer 相比 msg.sender 更消耗Gas
        // payable(i_owner).transfer(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawSend() external OnlyOwner {
        bool success = payable(msg.sender).send(200);
        if (!success) {
            revert EtherWallet__SendError();
        }
    }

    function withdrawCall() external OnlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert EtherWallet__CallError();
        }
    }

    // view/pure
    function getOwner() public view returns (address) {
        return i_owner;
    }
}
