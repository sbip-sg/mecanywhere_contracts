// SPDX-License-Identifier: MIT 
/*

Name: MecaTaskContract
Description: An on-chain Task contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./TaskAbstract.sol";

contract MecaTaskContract is MecaTaskAbstractContract
{
    // We have a list with all the tasks and a mapping to check if a task exists
    // and what is the position in the list of a task (if it exists is index + 1, if not is 0)
    mapping(bytes32 => uint32) public tasks_index;
    Task[] public tasks;

    constructor(uint256 taskAdditionFee)
        MecaTaskAbstractContract(taskAdditionFee)
    {
    }

    // External functions

    // External functions that are view

    function getTasks() external view override returns (Task[] memory)
    {
        return tasks;
    }

    // External functions that are pure

    // Public functions

    // Internal functions
    function _clear() internal override
    {
        // TODO: maybe go through task as pops and delete them
        for (uint256 i = 0; i < tasks.length; i++) {
            tasks_index[tasks[i].ipfsSha256] = 0;
        }
        delete tasks;
    }

    function _addTask(
        Task memory task
    ) internal override {
        if (tasks_index[task.ipfsSha256] != 0) {
            revert();
        }
        tasks.push(task);
        tasks_index[task.ipfsSha256] = uint32(tasks.length);
    }

    function _updateTaskFee(
        bytes32 ipfsSha256,
        uint256 fee
    ) internal override {
        tasks[_getTaskIndex(ipfsSha256) - 1].fee = fee;
    }

    function _updateTaskOwner(
        bytes32 ipfsSha256,
        address newOwner
    ) internal override {
        tasks[_getTaskIndex(ipfsSha256) - 1].owner = payable(newOwner);
    }

    function _updateTaskSize(
        bytes32 ipfsSha256,
        uint256 size
    ) internal override {
        tasks[_getTaskIndex(ipfsSha256) - 1].size = size;
    }

    function _deleteTask(
        bytes32 ipfsSha256
    ) internal override {
        uint32 index = _getTaskIndex(ipfsSha256);
        tasks[index - 1] = tasks[tasks.length - 1];
        tasks_index[tasks[index - 1].ipfsSha256] = index;
        tasks_index[ipfsSha256] = 0;
        tasks.pop();
    }

    function _getTask(
        bytes32 ipfsSha256
    )
        internal
        view
        override
        returns (Task memory)
    {
        return tasks[_getTaskIndex(ipfsSha256) - 1];
    }

    function _hasTask(
        bytes32 ipfsSha256
    )
        internal
        view
        override
        returns (bool)
    {
        uint32 index = tasks_index[ipfsSha256];
        return index != 0;
    }

    // Private functions
    /**
    * @notice get the index of the task given the ipfs hash
    * @param ipfsSha256 The IPFS hash of the task
    * @return uint32 The index of the task
    */
    function _getTaskIndex(
        bytes32 ipfsSha256
    )
        private
        view
        returns (uint32)
    {
        uint32 index = tasks_index[ipfsSha256];
        require(index != 0, "Task not found");
        return index;
    }

}