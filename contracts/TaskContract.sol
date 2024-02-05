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
    // TODO: maybe make like list and the mapping is jsut
    // for the index of the task in the list
    mapping(bytes32 => mapping(bytes32 => uint32)) public tasks_index;
    task[] public tasks;

    constructor() MecaTaskAbstractContract()
    {
    }

    function createTask(
        bytes32[2] calldata cid,
        uint256 fee,
        bytes1 computing_type
    ) public override returns (bool)
    {
        return true;
    }

    function getTask(
        bytes32[2] calldata cid
    ) public view override returns (task memory)
    {
        return task(cid, owner, 0, 0);
    }

    function getTaskFee(
        bytes32[2] calldata cid
    ) public view override returns (uint256)
    {
        return 0;
    }

    function updateTaskFee(
        bytes32[2] calldata cid,
        uint256 fee
    ) public override returns (bool)
    {
        return true;
    }

    function updateTaskOwner(
        bytes32[2] calldata cid,
        address new_owner
    ) public override returns (bool)
    {
        return true;
    }

    function deleteTask(
        bytes32[2] calldata cid
    ) public override returns (bool)
    {
        return true;
    }

    function getTasks(
    ) public view override returns (task[] memory)
    {
        return new task[](0);
    }
}