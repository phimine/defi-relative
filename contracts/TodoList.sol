// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title TodoList是类似便签一样功能的东西，记录我们需要做的事情，以及完成状态。
 * 1.需要完成的功能
 *   - 创建任务
 *   - 修改任务名称（任务名写错的时候）
 *   - 修改完成状态：
 *     a. 手动指定完成或者未完成
 *     b. 自动切换
 *       # 如果未完成状态下，改为完成
 *       # 如果完成状态，改为未完成
 *   - 获取任务
 * 2.思考代码内状态变量怎么安排？
 *   - 思考 1：思考任务 ID 的来源？ 我们在传统业务里，这里的任务都会有一个任务 ID，在区块链里怎么实现？？
 *     答：传统业务里，ID 可以是数据库自动生成的，也可以用算法来计算出来的，比如使用雪花算法计算出 ID 等。
 *        在区块链里我们使用数组的 index 索引作为任务的 ID，也可以使用自增的整型数据来表示。
 *   - 思考 2: 我们使用什么数据类型比较好？
 *     答：因为需要任务 ID，如果使用数组 index 作为任务 ID。则数据的元素内需要记录任务名称，任务完成状态，所以元素使用 struct 比较好。
 *        如果使用自增的整型作为任务 ID，则整型 ID 对应任务，使用 mapping 类型比较符合。
 * @author Carl Fu
 * @notice
 */
contract TodoList {
    // Type Declation
    struct Task {
        string name;
        bool completed;
    }
    // State Variable
    Task[] private _tasks;

    // Event
    event TaskCreated(string name);
    event RenameTask(uint256 indexed id, string oldName, string newName);
    event TaskStatusChanged(uint256 indexed id, bool updatedStatus);

    // Modifier

    // Constructor
    constructor() {
        Task memory initTask = Task("Init Task", false);
        _tasks.push(initTask);
    }

    // Functions
    /**
     * 创建任务
     * @param name 任务名
     */
    function createTask(string calldata name) external {
        Task memory _task = Task(name, false);
        _tasks.push(_task);
        emit TaskCreated(name);
    }

    function renameTask(uint256 index, string calldata newName) external {
        Task memory _task = _tasks[index];
        // Task storage _task = _tasks[index]; // 方法2: 先获取储存到 storage，在修改，在修改多个属性的时候比较省 gas
        string memory oldName = _task.name;
        _task.name = newName;
        emit RenameTask(index, oldName, newName);
    }

    function changeTaskStatus(uint256 index, bool completed) external {
        Task memory _task = _tasks[index];
        _task.completed = completed;
        emit TaskStatusChanged(index, _task.completed);
    }

    function toggleTaskStatus(uint256 index) external {
        Task memory _task = _tasks[index];
        _task.completed = !_task.completed;
        emit TaskStatusChanged(index, _task.completed);
    }

    function getTask(
        uint256 id
    ) public view returns (string memory name, bool completed) {
        Task memory _task = _tasks[id]; // memory : 2次拷贝
        // Task storage _task = _tasks[id]; // storage : 1次拷贝，相较于上面的方法gas更低些
        return (_task.name, _task.completed);
    }
}
