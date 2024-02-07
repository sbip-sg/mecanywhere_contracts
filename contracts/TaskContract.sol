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
    task[] public tasks;

    uint256 public constant TASK_FEE = 5 wei;

    constructor() MecaTaskAbstractContract()
    {
    }

    function createTask(
        bytes32 ipfs_sha256,
        uint256 fee,
        uint8 computing_type,
        uint256 size
    ) public payable override returns (bool)
    {
        if (msg.value != TASK_FEE) {
            revert();
        }
        if (tasks_index[ipfs_sha256] != 0) {
            return false;
        }
        tasks.push(task(ipfs_sha256, msg.sender, fee, computing_type, size));
        tasks_index[ipfs_sha256] = uint32(tasks.length);
        return true;
    }

    function getTask(
        bytes32 ipfs_sha256
    ) public view override returns (task memory)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        return tasks[index - 1];
    }

    function updateTaskFee(
        bytes32 ipfs_sha256,
        uint256 fee
    ) public override returns (bool)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        tasks[index - 1].fee = fee;
        return true;
    }

    function updateTaskOwner(
        bytes32 ipfs_sha256,
        address new_owner
    ) public override returns (bool)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        tasks[index - 1].owner = new_owner;
        return true;
    }

    function updateTaskSize(
        bytes32 ipfs_sha256,
        uint256 size
    ) public override returns (bool)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        tasks[index - 1].size = size;
        return true;
    }

    function updateTaskComputingType(
        bytes32 ipfs_sha256,
        uint8 computing_type
    ) public override returns (bool)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        tasks[index - 1].computing_type = computing_type;
        return true;
    }

    function deleteTask(
        bytes32 ipfs_sha256
    ) public override returns (bool)
    {
        uint32 index = tasks_index[ipfs_sha256];
        if (index == 0) {
            revert("Task not found");
        }
        tasks[index - 1] = tasks[tasks.length - 1];
        tasks_index[tasks[index - 1].ipfs_sha256] = index;
        tasks_index[ipfs_sha256] = 0;
        tasks.pop();
        return true;
    }

    function getTasks(
    ) public view override returns (task[] memory)
    {
        return tasks;
    }
}