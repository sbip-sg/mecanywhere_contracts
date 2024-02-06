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
        uint8 computing_type;
        uint256 size;
    }

    constructor() 
    {
        owner = tx.origin;
    }

    function createTask(
        bytes32[2] calldata cid,
        uint256 fee,
        uint8 computing_type,
        uint256 size
    ) public payable virtual returns (bool);

    function getTask(
        bytes32[2] calldata cid
    ) public view virtual returns (task memory);

    function getTaskFee(
        bytes32[2] calldata cid
    ) public view returns (uint256)
    {
        return getTask(cid).fee;
    }

    function getTaskSize(
        bytes32[2] calldata cid
    ) public view returns (uint256)
    {
        return getTask(cid).size;
    }

    function getTaskComputingType(
        bytes32[2] calldata cid
    ) public view returns (uint8)
    {
        return getTask(cid).computing_type;
    }

    function getTaskOwner(
        bytes32[2] calldata cid
    ) public view returns (address)
    {
        return getTask(cid).owner;
    }

    function updateTaskFee(
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool);

    function updateTaskOwner(
        bytes32[2] calldata cid,
        address new_owner
    ) public virtual returns (bool);

    function updateTaskSize(
        bytes32[2] calldata cid,
        uint256 size
    ) public virtual returns (bool);

    function updateTaskComputingType(
        bytes32[2] calldata cid,
        uint8 computing_type
    ) public virtual returns (bool);

    function deleteTask(
        bytes32[2] calldata cid
    ) public virtual returns (bool);

    function getTasks(
    ) public view virtual returns (task[] memory);

}