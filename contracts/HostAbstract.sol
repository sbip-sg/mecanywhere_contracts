// SPDX-License-Identifier: MIT 
/*

Name: MecaHostAbstractContract
Description: An on-chain  abstract Host contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

abstract contract MecaTaskFee
{
    uint8 public fee_type;

    constructor(uint8 _fee_type) 
    {
        fee_type = _fee_type;
    }

    // for static fee
    function getFee(
    ) public view virtual returns (uint256);

    // for dynamic fee on input
    function getFeeInput(
        bytes[] calldata input
    ) public view virtual returns (uint256);

    // for size fee
    function getFeeSize(
        uint256 size
    ) public view virtual returns (uint256);

    function getFeeType(
    ) public view returns (uint8)
    {
        return fee_type;
    }

}

contract MecaTaskFeeStatic is MecaTaskFee
{
    uint256 public fee;

    constructor(uint256 _fee) MecaTaskFee(0)
    {
        fee = _fee;
    }

    function getFee(
    ) public view override returns (uint256)
    {
        return fee;
    }

    function getFeeInput(
        bytes[] calldata input
    ) public view override returns (uint256)
    {
        return fee;
    }

    function getFeeSize(
        uint256 size
    ) public view override returns (uint256)
    {
        return fee;
    }

}

contract MecaTaskFeeSize is MecaTaskFee
{
    uint256 public fee;

    constructor(uint256 _fee) MecaTaskFee(1)
    {
        fee = _fee;
    }

    function getFee(
    ) public view override returns (uint256)
    {
        return fee;
    }

    function getFeeInput(
        bytes[] calldata input
    ) public view override returns (uint256)
    {
        return fee;
    }

    function getFeeSize(
        uint256 size
    ) public view override returns (uint256)
    {
        return fee * size;
    }

}

abstract contract MecaHostAbstractContract
{
    address public owner;

    struct host_task {
        uint256 block_timeout;
        MecaTaskFee task_fee_contract;
    }

    struct host {
        address owner;
        bytes[] public_key;
        uint8 public_key_type;
        uint256 block_timeout_limit;
        uint256 stake;
    }

    constructor() 
    {
        owner = tx.origin;
    }

    function registerHost(
        bytes[] calldata public_key,
        uint8 public_key_type,
        uint256 block_timeout_limit
    ) public payable virtual returns (bool);

    function addStake(
    ) public payable virtual returns (bool);

    function getHostPublicKey(
        address host_address
    ) public view virtual returns (bytes[] memory, uint8);

    function getHostBlockTimeoutLimit(
        address host_address
    ) public view virtual returns (uint256);

    function getTaskFeeContract(
        address host_address,
        bytes32[2] calldata cid
    ) public view virtual returns (MecaTaskFee);

    function getTaskBlockTimeout(
        address host_address,
        bytes32[2] calldata cid
    ) public view virtual returns (uint256);

    function getTaskFeeType(
        address host_address,
        bytes32[2] calldata cid
    ) public view returns (uint8)
    {
        return getTaskFeeContract(host_address, cid).getFeeType();
    }

    function getTaskFee(
        address host_address,
        bytes32[2] calldata cid
    ) public view returns (uint256)
    {
        return getTaskFeeContract(host_address, cid).getFee();
    }

    function setTaskFeeContract(
        bytes32[2] calldata cid,
        MecaTaskFee task_fee_contract
    ) public virtual returns (bool);

    function setTaskFeeStaticContract(
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool) {
        return setTaskFeeContract(
            cid,
            new MecaTaskFeeStatic(fee));
    }

    function setTaskFeeSizeContract(
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool) {
        return setTaskFeeContract(
            cid,
            new MecaTaskFeeSize(fee));
    }

    function setTaskBlockTimeout(
        bytes32[2] calldata cid,
        uint256 block_timeout
    ) public virtual returns (bool);

    function addTask(
        bytes32[2] calldata cid,
        uint256 block_timeout_limit,
        MecaTaskFee task_fee_contract
    ) public virtual returns (bool) {
        return setTaskBlockTimeout(cid, block_timeout_limit) &&setTaskFeeContract(cid, task_fee_contract); 
    }

    function addStaticTask(
        bytes32[2] calldata cid,
        uint256 block_timeout_limit,
        uint256 fee
    ) public virtual returns (bool) {
        return addTask(cid, block_timeout_limit, new MecaTaskFeeStatic(fee));
    }

    function addSizeTask(
        bytes32[2] calldata cid,
        uint256 block_timeout_limit,
        uint256 fee
    ) public virtual returns (bool) {
        return addTask(cid, block_timeout_limit, new MecaTaskFeeSize(fee));
    }

    function deleteTask(
        bytes32[2] calldata cid
    ) public virtual returns (bool);

    function getHosts(
    ) public view virtual returns (host[] memory);

    function updateBlockTimeoutLimit(
        address host_address,
        uint256 block_timeout_limit
    ) public virtual returns (bool);

    function updateHostPublicKey(
        address host_address,
        bytes[] calldata public_key,
        uint8 public_key_type
    ) public virtual returns (bool);

    function deleteHost(
        address host_address
    ) public virtual returns (bool);

}