// SPDX-License-Identifier: MIT 
/*

Name: MecaTaskAbstractContract
Description: An on-chain  abstract Task contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;


/**
* @title MecaTaskAbstractContract
* @author Ciocirlan Stefan-Dan (sdcioc)
* @notice The Task abstract contract for the MECA ecosystem
* @dev Give the Task structure and and
* external function for the Task contract
*/
abstract contract MecaTaskAbstractContract
{
    /// The owner of the contract
    address payable public owner;
    uint256 public TASK_ADDITION_FEE;

    /**
    * @notice The Task structure
    * @param ipfsSha256 The IPFS hash of the task
    * @param owner The owner of the task
    * @param fee The fee of the task
    * @param computingType The type of computing (0: cpu / 1: gpu)
    * @param size The i/o size of the task (in bytes)
    */
    struct Task {
        bytes32 ipfsSha256;
        address payable owner;
        uint256 fee;
        uint8 computingType;
        uint256 size;
    }

    // custom modifiers
    /**
    * @notice The onlyOwner modifier
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }
    /**
    * @notice The onlyTaskOwner modifier
    * @param ipfsSha256 The IPFS hash of the task
    */
    modifier onlyTaskOwner(bytes32 ipfsSha256) {
        require(
            msg.sender == _getTask(ipfsSha256).owner,
            "Task owner only"
        );
        _;
    }

    /**
    * @notice The hasFee modifier
    */
    modifier hasFee() {
        require(msg.value == TASK_ADDITION_FEE, "Fee required");
        _;
    }

    /**
    * @notice The constructor
    * @param taskAdditionFee The fee for adding a task
    */
    constructor(uint256 taskAdditionFee) 
    {
        owner = payable(tx.origin);
        TASK_ADDITION_FEE = taskAdditionFee;
    }

    /**
    * @notice The receive function
    */
    receive() external payable {
        revert();
    }

    /**
    * @notice The fallback function
    */
    fallback() external payable {
        revert();
    }

    /**
    * @notice The clear function
    * @dev This function is used to clear the contract
    */
    function clear() external onlyOwner {
        _clear();
    }

    // External functions
    /**
    * @notice The addTask function
    * @dev This function is used to add a task to the contract
    * The function is payable and the fee is sent to the contract
    * and kept as a stake and it returns to the task owner when
    * the task is deleted
    * @param ipfsSha256 The IPFS hash of the task
    * @param fee The fee of the task
    * @param computingType The type of computing (0: cpu / 1: gpu)
    * @param size The i/o size of the task (in bytes)
    */
    function addTask(
        bytes32 ipfsSha256,
        uint256 fee,
        uint8 computingType,
        uint256 size
    )
        external
        payable
        hasFee
    {
        require(
            _hasTask(ipfsSha256) == false,
            "Existent task"
        );
        _addTask(
            Task({
                ipfsSha256: ipfsSha256,
                owner: payable(msg.sender),
                fee: fee,
                computingType: computingType,
                size: size
            })
        );
    }

    /**
    * @notice Updates the task fee
    * @param ipfsSha256 The IPFS hash of the task
    * @param newFee The new fee of the task
    */
    function updateTaskFee(
        bytes32 ipfsSha256,
        uint256 newFee
    )
        external
        onlyTaskOwner(ipfsSha256)
    {
        _updateTaskFee(ipfsSha256, newFee);
    }

    /**
    * @notice Updates the task owner
    * @param ipfsSha256 The IPFS hash of the task
    * @param newOwner The new owner of the task
    */
    function updateTaskOwner(
        bytes32 ipfsSha256,
        address newOwner
    )
        external
        onlyTaskOwner(ipfsSha256)
    {
        _updateTaskOwner(ipfsSha256, newOwner);
    }

    /**
    * @notice Updates the task i/o size
    * @param ipfsSha256 The IPFS hash of the task
    * @param newSize The new i/o size of the task
    */
    function updateTaskSize(
        bytes32 ipfsSha256,
        uint256 newSize
    )
        external
        onlyTaskOwner(ipfsSha256)
    {
        _updateTaskSize(ipfsSha256, newSize);
    }

    /**
    * @notice Deletes a task
    * @dev Return the task fee to the owner
    * @param ipfsSha256 The IPFS hash of the task
    */
    function deleteTask(
        bytes32 ipfsSha256
    )
        external
        onlyTaskOwner(ipfsSha256)
    {
        address payable taskOwner = _getTask(ipfsSha256).owner;
        _deleteTask(ipfsSha256);
        taskOwner.transfer(TASK_ADDITION_FEE);
    }

    // View External functions
    /**
    * @notice Get the task fee for the task developer
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint256 The fee of the task
    */
    function getTaskFee(
        bytes32 ipfsSha256
    )
        external
        view
        returns (uint256)
    {
        return _getTask(ipfsSha256).fee;
    }

    /**
    * @notice Get the task i/o size for the task
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint256 The i/o size of the task
    */
    function getTaskSize(
        bytes32 ipfsSha256
    )
        external
        view
        returns (uint256)
    {
        return _getTask(ipfsSha256).size;
    }

    /**
    * @notice Get the task computing type for the task
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint8 The computing type of the task
    */
    function getTaskComputingType(
        bytes32 ipfsSha256
    )
        external
        view
        returns (uint8)
    {
        return _getTask(ipfsSha256).computingType;
    }

    /**
    * @notice Get the task owner for the task
    * @param ipfsSha256 The IPFS hash of the task
    * @return address The owner of the task
    */
    function getTaskOwner(
        bytes32 ipfsSha256
    )
        external
        view
        returns (address)
    {
        return _getTask(ipfsSha256).owner;
    }

    /**
    * @notice Get all the tasks
    * @return task[] The tasks
    */
    function getTasks() external view virtual returns (Task[] memory);

    // Pure External functions

    // Public functions

    // Internal functions

    /**
    * @notice The _clear function
    * @dev This function is used to clear the contract storage
    */
    function _clear() internal virtual;

    /**
    * @notice The _addTask function
    * @dev This function is used to add a task to the contract
    * @param task The task to be added
    */
    function _addTask(
        Task memory task
    ) internal virtual;

    /**
    * @notice Updates the task fee
    * @param ipfsSha256 The IPFS hash of the task
    * @param newFee The new fee of the task
    */
    function _updateTaskFee(
        bytes32 ipfsSha256,
        uint256 newFee
    ) internal virtual;

    /**
    * @notice Updates the task owner
    * @param ipfsSha256 The IPFS hash of the task
    * @param newOwner The new owner of the task
    */
    function _updateTaskOwner(
        bytes32 ipfsSha256,
        address newOwner
    ) internal virtual;

    /**
    * @notice Updates the task i/o size
    * @param ipfsSha256 The IPFS hash of the task
    * @param newSize The new i/o size of the task
    */
    function _updateTaskSize(
        bytes32 ipfsSha256,
        uint256 newSize
    ) internal virtual;

    /**
    * @notice Deletes a task
    * @param ipfsSha256 The IPFS hash of the task
    */
    function _deleteTask(
        bytes32 ipfsSha256
    ) internal virtual;

    /**
    * @notice get the task given the ipfs hash
    * @param ipfsSha256 The IPFS hash of the task
    * @return Task The task
    */
    function _getTask(
        bytes32 ipfsSha256
    )
        internal
        view
        virtual
        returns (Task memory);
    
    /**
    * @notice if the task exists
    * @param ipfsSha256 The IPFS hash of the task
    * @return bool if the task exists
    */
    function _hasTask(
        bytes32 ipfsSha256
    )
        internal
        view
        virtual
        returns (bool);

    // Private functions

}