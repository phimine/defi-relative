// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

error WETH__InsuffienceBalance();
error WETH__InsuffienceAllowance();

/**
 * @title WETH 是包装 ETH 主币，作为 ERC20 的合约。 标准的 ERC20 合约包括如下几个
 * 3 个查询
 *   - balanceOf: 查询指定地址的 Token 数量
 *   - allowance: 查询指定地址对另外一个地址的剩余授权额度
 *   - totalSupply: 查询当前合约的 Token 总量
 * 2 个交易
 *   - transfer: 从当前调用者地址发送指定数量的 Token 到指定地址。
 *     这是一个写入方法，所以还会抛出一个 Transfer 事件。
 *   - transferFrom: 当向另外一个合约地址存款时，对方合约必须调用 transferFrom 才可以把 Token 拿到它自己的合约中。
 * 2 个事件
 *   - Transfer
 *   - Approval
 * 1 个授权
 *  - approve: 授权指定地址可以操作调用者的最大 Token 数量。
 * @author Carl Fu
 * @notice
 */
contract WETH {
    // State Variable
    string private constant _name = "Wrapped Ether";
    string private constant _symbol = "WETH";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    // Event
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed delegator,
        uint256 amount
    );
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(uint256 amount);

    // Modifier
    modifier EnoughBalance(address account, uint256 amount) {
        uint256 curBalance = balanceOf(account);
        if (curBalance < amount) {
            revert WETH__InsuffienceBalance();
        }
        _;
    }

    // Constructor
    constructor() {}

    // Functions
    // receive/fallback
    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }

    // external/payable functions
    /**
     * Deposit
     */
    function deposit() public payable {
        _balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * Withdraw
     */
    function withdraw(
        uint256 amount
    ) external EnoughBalance(msg.sender, amount) {
        payable(msg.sender).transfer(amount);
        emit Withdraw(amount);
    }

    function approve(
        address delegator,
        uint256 amount
    ) external returns (bool) {
        _allowance[msg.sender][delegator] = amount;
        emit Approval(msg.sender, delegator, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public EnoughBalance(from, amount) returns (bool) {
        if (from != msg.sender) {
            if (allowance(from, msg.sender) < amount) {
                revert WETH__InsuffienceAllowance();
            }
            _allowance[from][msg.sender] -= amount;
        }
        _balance[from] -= amount;
        _balance[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // View/Pure Functions
    function balanceOf(address addr) public view returns (uint256) {
        return _balance[addr];
    }

    function allowance(
        address owner,
        address delegator
    ) public view returns (uint256) {
        return _allowance[owner][delegator];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }
}
