// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Error
error MultiSignWallet_NotOwnerError();
error MultiSignWallet_EmptyOwnerListError();
error MultiSignWallet_InvalidOwnerError();
error MultiSignWallet_DuplicatedOwnerError();
error MultiSignWallet_InvalidRequiresError();

error MultiSignWallet_AleadyApprovedError();
error MultiSignWallet_NotApprovedError();
error MultiSignWallet_TransactionNotExistError();
error MultiSignWallet_TransactionExecutedError();
error MultiSignWallet_InffienceApproverError(
    uint256 requires,
    uint256 approvers
);
error MultiSignWallet_TransactionExecuteFailedError(
    address executor,
    address to,
    uint256 amount,
    bytes data
);

/**
 * @title 多签钱包的功能: 合约有多个 owner，一笔交易发出后，需要多个 owner 确认，确认数达到最低要求数之后，才可以真正的执行。
 * - 部署时候传入地址参数和需要的签名数
 *      多个 owner 地址
 *      发起交易的最低签名数
 * - 有接受 ETH 主币的方法，
 * - 除了存款外，其他所有方法都需要 owner 地址才可以触发
 * - 发送前需要检测是否获得了足够的签名数
 * - 使用发出的交易数量值作为签名的凭据 ID（类似上么）
 * - 每次修改状态变量都需要抛出事件
 * - 允许批准的交易，在没有真正执行前取消。
 * - 足够数量的 approve 后，才允许真正执行。

 * @author Carl Fu
 * @notice 
 */
contract MultiSignWallet {
    // Type Declaration
    struct Transaction {
        address to;
        uint256 amount;
        bytes data;
        bool executed;
    }

    // State Variable
    address[] private owners;
    uint256 private immutable i_requires;
    mapping(address => bool) private isOwner;

    Transaction[] private transactions;
    mapping(uint256 => mapping(address => bool)) private approvedMap;
    // Event
    event LogAlert(
        string message,
        address indexed from,
        uint256 amount,
        bytes data
    );
    event Submit(address indexed from, uint256 indexed txId);
    event Approve(address indexed approver, uint256 indexed txId);
    event Revoke(address indexed approver, uint256 indexed txId);
    event Execute(address indexed executor, uint256 indexed txId);

    // Modifier
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert MultiSignWallet_NotOwnerError();
        }
        _;
    }

    modifier notApproved(uint256 txId) {
        if (approvedMap[txId][msg.sender]) {
            revert MultiSignWallet_AleadyApprovedError();
        }
        _;
    }

    modifier txExists(uint256 txId) {
        if (transactions.length <= txId) {
            revert MultiSignWallet_TransactionNotExistError();
        }
        _;
    }

    modifier notExecuted(uint256 txId) {
        if (transactions[txId].executed) {
            revert MultiSignWallet_TransactionExecutedError();
        }
        _;
    }

    modifier approved(uint256 txId) {
        if (!approvedMap[txId][msg.sender]) {
            revert MultiSignWallet_NotApprovedError();
        }
        _;
    }

    modifier executable(uint256 txId) {
        uint256 approverCount = getApproveCount(txId);
        if (approverCount < i_requires) {
            revert MultiSignWallet_InffienceApproverError(
                i_requires,
                approverCount
            );
        }
        _;
    }

    // Constructor
    constructor(address[] memory _owners, uint256 _requires) {
        if (_owners.length <= 0) {
            revert MultiSignWallet_EmptyOwnerListError();
        }

        if (_requires < 0 || _requires > _owners.length) {
            revert MultiSignWallet_InvalidRequiresError();
        }

        for (uint256 index = 0; index < _owners.length; index++) {
            address _owner = _owners[index];
            if (_owner == address(0)) {
                revert MultiSignWallet_InvalidOwnerError();
            }
            if (isOwner[_owner]) {
                revert MultiSignWallet_DuplicatedOwnerError();
            }
            isOwner[_owner] = true;
            owners.push(_owner);
        }
        i_requires = _requires;
    }

    // Functions
    // receive/fallback
    receive() external payable {
        emit LogAlert("receive", msg.sender, msg.value, "");
    }

    // external
    function submit(
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner returns (uint256 txId) {
        transactions.push(Transaction(_to, _amount, _data, false));
        txId = transactions.length - 1;
        emit Submit(msg.sender, txId);
    }

    function approve(
        uint256 txId
    ) external onlyOwner txExists(txId) notExecuted(txId) notApproved(txId) {
        approvedMap[txId][msg.sender] = true;
        emit Approve(msg.sender, txId);
    }

    function revoke(
        uint256 txId
    ) external onlyOwner txExists(txId) notExecuted(txId) approved(txId) {
        approvedMap[txId][msg.sender] = false;
        emit Revoke(msg.sender, txId);
    }

    function execute(
        uint256 txId
    ) external onlyOwner txExists(txId) notExecuted(txId) executable(txId) {
        // 1. 检查 - modifier
        // 2. 修改
        Transaction storage transaction = transactions[txId];
        transaction.executed = true;

        // 3. 操作
        (bool success, ) = payable(transaction.to).call{
            value: transaction.amount
        }(transaction.data);
        if (!success) {
            revert MultiSignWallet_TransactionExecuteFailedError(
                msg.sender,
                transaction.to,
                transaction.amount,
                transaction.data
            );
        }
        emit Execute(msg.sender, txId);
    }

    // view/pure
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getApproveCount(uint256 txId) public view returns (uint256 count) {
        for (uint256 index = 0; index < owners.length; index++) {
            if (approvedMap[txId][owners[index]]) {
                count += 1;
            }
        }
    }
}
