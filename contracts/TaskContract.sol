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
    mapping(bytes32 => mapping(bytes32 => uint32)) public tasks_index;
    task[] public tasks;

    uint256 public constant TASK_FEE = 0.001 ether;

    constructor() MecaTaskAbstractContract()
    {
    }

    function createTask(
        bytes32[2] calldata cid,
        uint256 fee,
        uint8 computing_type
    ) public payable override returns (bool)
    {
        if (msg.value != TASK_FEE) {
            revert();
        }
        if (tasks_index[cid[0]][cid[1]] != 0) {
            return false;
        }
        tasks.push(task(cid, msg.sender, fee, computing_type));
        tasks_index[cid[0]][cid[1]] = uint32(tasks.length);
        return true;
    }

    function getTask(
        bytes32[2] calldata cid
    ) public view override returns (task memory)
    {
        uint32 index = tasks_index[cid[0]][cid[1]];
        if (index == 0) {
            return task(cid, address(0), 0, 0);
        }
        return tasks[index - 1];
    }

    function getTaskFee(
        bytes32[2] calldata cid
    ) public view override returns (uint256)
    {
        uint32 index = tasks_index[cid[0]][cid[1]];
        if (index == 0) {
            return 0;
        }
        return tasks[index - 1].fee;
    }

    function updateTaskFee(
        bytes32[2] calldata cid,
        uint256 fee
    ) public override returns (bool)
    {
        uint32 index = tasks_index[cid[0]][cid[1]];
        if (index == 0) {
            return false;
        }
        tasks[index - 1].fee = fee;
        return true;
    }

    function updateTaskOwner(
        bytes32[2] calldata cid,
        address new_owner
    ) public override returns (bool)
    {
        uint32 index = tasks_index[cid[0]][cid[1]];
        if (index == 0) {
            return false;
        }
        tasks[index - 1].owner = new_owner;
        return true;
    }

    function deleteTask(
        bytes32[2] calldata cid
    ) public override returns (bool)
    {
        uint32 index = tasks_index[cid[0]][cid[1]];
        if (index == 0) {
            return false;
        }
        tasks[index - 1] = tasks[tasks.length - 1];
        tasks_index[tasks[index - 1].cid[0]][tasks[index - 1].cid[1]] = index;
        tasks_index[cid[0]][cid[1]] = 0;
        tasks.pop();
        return true;
    }

    function getTasks(
    ) public view override returns (task[] memory)
    {
        return tasks;
    }
}