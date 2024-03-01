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
        bytes32 ipfs_sha256;
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
        bytes32 ipfs_sha256,
        uint256 fee,
        uint8 computing_type,
        uint256 size
    ) public payable virtual returns (bool);

    function getTask(
        bytes32 ipfs_sha256
    ) public view virtual returns (task memory);

    function getTaskFee(
        bytes32 ipfs_sha256
    ) public view returns (uint256)
    {
        return getTask(ipfs_sha256).fee;
    }

    function getTaskSize(
        bytes32 ipfs_sha256
    ) public view returns (uint256)
    {
        return getTask(ipfs_sha256).size;
    }

    function getTaskComputingType(
        bytes32 ipfs_sha256
    ) public view returns (uint8)
    {
        return getTask(ipfs_sha256).computing_type;
    }

    function getTaskOwner(
        bytes32 ipfs_sha256
    ) public view returns (address)
    {
        return getTask(ipfs_sha256).owner;
    }

    function updateTaskFee(
        bytes32 ipfs_sha256,
        uint256 fee
    ) public virtual returns (bool);

    function updateTaskOwner(
        bytes32 ipfs_sha256,
        address new_owner
    ) public virtual returns (bool);

    function updateTaskSize(
        bytes32 ipfs_sha256,
        uint256 size
    ) public virtual returns (bool);

    function updateTaskComputingType(
        bytes32 ipfs_sha256,
        uint8 computing_type
    ) public virtual returns (bool);

    function deleteTask(
        bytes32 ipfs_sha256
    ) public virtual returns (bool);

    function getTasks(
    ) public view virtual returns (task[] memory);

}