// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

error CrowdFunding__ClosedError();

/**
 * @title 众筹合约是一个募集资金的合约，在区块链上，我们是募集以太币，类似互联网业务的水滴筹。区块链早起的 ICO 就是类似业务。
 * 需求分析：
 * 1. 众筹合约分为两种角色：一个是受益人（一个地址），一个是资助者（可以是多个地址）。
 * 2. 状态变量：筹资目标、当前筹资数量、资助者信息、资助人个数
 * 3. 构造函数，传入 受益人+目标数量
 * 4. 函数：资助
 * 5. 销毁函数：替代selfdestruct
 * @author Carl Fu
 * @notice
 */
contract CrowdFunding {
    // Type Declaration
    // State Variable
    address private immutable i_beneficiary;
    uint256 private immutable i_fundingGoal;
    uint256 private _fundingAmount; // 当前筹资数量
    mapping(address => uint256) private _funders;
    mapping(address => bool) private _fundersInserted;
    address[] private _fundersKey;

    bool public AVAIABLE = true; // 合约状态

    // Event
    event Fund(address indexed funder, uint256 amount);
    event FundingClosed();

    // Modifier
    modifier Opened() {
        if (!AVAIABLE) {
            revert CrowdFunding__ClosedError();
        }
        _;
    }

    // Constructor
    constructor(address beneficiary, uint256 fundingGoal) {
        i_beneficiary = beneficiary;
        i_fundingGoal = fundingGoal;
    }

    // Functions
    // external/payable
    function contribute() external payable Opened {
        uint256 finalAmount = _fundingAmount + msg.value;
        uint256 refundAmount = 0;

        if (finalAmount > i_fundingGoal) {
            refundAmount = finalAmount - i_fundingGoal;
            _funders[msg.sender] += i_fundingGoal - _fundingAmount;
            _fundingAmount = i_fundingGoal;
        } else {
            _funders[msg.sender] += msg.value;
            _fundingAmount += msg.value;
        }

        // 记录资助者
        if (!_fundersInserted[msg.sender]) {
            _fundersInserted[msg.sender] = true;
            _fundersKey.push(msg.sender);
        }

        // 退还多余的资助
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function close() external Opened returns (bool) {
        // 1. 检查：筹资目标是否达成
        if (_fundingAmount < i_fundingGoal) {
            return false;
        }

        // 2. 修改：筹资数量清空，状态false
        uint256 amount = _fundingAmount;
        _fundingAmount = 0;
        AVAIABLE = false;

        // 3. 操作：资金发放给受益人
        payable(i_beneficiary).transfer(amount);
        return true;
    }

    // view/pure
    function status() public view returns (bool) {
        return AVAIABLE;
    }

    function fundingAmount() public view returns (uint256) {
        return _fundingAmount;
    }

    function funderCount() public view returns (uint256) {
        return _fundersKey.length;
    }
}
