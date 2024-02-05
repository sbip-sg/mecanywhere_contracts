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
        address host_address
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

    function setTaskFeeContract(
        address host_address,
        bytes32[2] calldata cid,
        MecaTaskFee task_fee_contract
    ) public virtual returns (bool);

    function setTaskFeeStaticContract(
        address host_address,
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool) {
        return setTaskFeeContract(
            host_address,
            cid,
            new MecaTaskFeeStatic(fee));
    }

    function setTaskFeeSizeContract(
        address host_address,
        bytes32[2] calldata cid,
        uint256 fee
    ) public virtual returns (bool) {
        return setTaskFeeContract(
            host_address,
            cid,
            new MecaTaskFeeSize(fee));
    }

    function deleteTaskFeeContract(
        address host_address,
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