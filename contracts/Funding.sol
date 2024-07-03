// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Error
error Funding__ClosedError();

/**
 * @title
 * @author
 * @notice
 */
contract Funding {
    // Type Declaration
    // State Variable
    address private immutable i_beneficiary;
    uint256 private immutable i_fundingGoal;

    uint256 private fundingAmount;
    mapping(address => uint256) private funders;
    mapping(address => bool) private funderInserted;
    address[] private funderKeys;

    uint256 private funderCount;
    bool public AVAIABLE = true;

    // Event
    // Modifier
    modifier Opened() {
        if (!AVAIABLE) {
            revert Funding__ClosedError();
        }
        _;
    }

    // Constructor
    constructor(address beneficiary, uint256 fundingGoal) {
        i_beneficiary = beneficiary;
        i_fundingGoal = fundingGoal;
    }

    // Functions
    // receive/fallback
    // external/public
    function contribute() external payable Opened {
        uint256 finalAmount = fundingAmount + msg.value;
        uint256 refundAmount = 0;
        if (finalAmount > i_fundingGoal) {
            refundAmount = finalAmount - i_fundingGoal;

            uint256 actualFunding = fundingAmount - refundAmount;
            funders[msg.sender] += actualFunding;
            fundingAmount += actualFunding;
        } else {
            funders[msg.sender] += msg.value;
            fundingAmount += msg.value;
        }

        if (!funderInserted[msg.sender]) {
            funderInserted[msg.sender] = true;
            funderKeys.push(msg.sender);
        }

        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function withdraw() external Opened returns (bool) {
        // 1. 检查 Check
        if (fundingAmount < i_fundingGoal) {
            return false;
        }

        uint256 amount = fundingAmount;
        // 2. 修改
        fundingAmount = 0;
        AVAIABLE = false;

        // 3. 操作
        payable(i_beneficiary).transfer(amount);
        return true;
    }

    // view/pure
    function getFunderCount() public view returns (uint256) {
        return funderKeys.length;
    }

    function getFundingAmount() public view returns (uint256) {
        return fundingAmount;
    }

    function getFunderAmount(address funder) public view returns (uint256) {
        return funders[funder];
    }
}
