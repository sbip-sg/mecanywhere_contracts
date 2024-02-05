// SPDX-License-Identifier: MIT 
/*

Name: MecaTaskAbstractContract
Description: An on-chain  abstract Task contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

abstract contract MecaTaskAbstractContract
{
    address public owner;

    struct task {
        bytes32[2] cid;
        address owner;
        uint256 fee;
        bytes1 computing_type;
    }

    constructor() 
    {
        owner = tx.origin;
    }

    function createTask(
        bytes32[2] calldata cid,
        uint256 fee,
        bytes1 computing_type
    ) public virtual returns (bool);

    function getTask(
        bytes32[2] calldata cid
    ) public view virtual returns (task memory);

    function getTaskFee(
        bytes32[2] calldata cid
    ) public view virtual returns (uint256);

    function updateTaskFee(
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool);

    function updateTaskOwner(
        bytes32[2] calldata cid,
        address new_owner
    ) public virtual returns (bool);

    function deleteTask(
        bytes32[2] calldata cid
    ) public virtual returns (bool);

    function getTasks(
    ) public view virtual returns (task[] memory);

}