// SPDX-License-Identifier: MIT 
/*

Name: MecaSchedulerAbstractContract
Description: An on-chain  abstract Scheduler contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./TowerAbstract.sol";
import "./HostAbstract.sol";
import "./TaskAbstract.sol";


abstract contract MecaSchedulerAbstractContract
{
    address public owner;

    MecaHostAbstractContract public meca_host_contract;
    MecaTaskAbstractContract public meca_task_contract;
    MecaTowerAbstractContract public meca_tower_contract;

    struct running_task_fee 
    {
        uint256 tower_fee;
        uint256 host_fee;
        uint256 scheduler_fee;
        uint256 task_fee;
        uint256 insurance_fee;
    }

    struct running_task {
        bytes32[2] cid;
        bytes32 input_hash;
        uint256 size;
        address tower_address;
        address host_address;
        address owner;
        uint256 start_block;
        uint256 block_timeout_limit;
        running_task_fee fee;
    }

    constructor() 
    {
        owner = tx.origin;
    }

    function setHostContract(
        address host_contract
    ) public virtual returns (bool) {
        require(msg.sender == owner, "Owner only");
        meca_host_contract = MecaHostAbstractContract(host_contract);
        return true;
    }

    function setTaskContract(
        address task_contract
    ) public virtual returns (bool) {
        require(msg.sender == owner, "Owner only");
        meca_task_contract = MecaTaskAbstractContract(task_contract);
        return true;
    }

    function setTowerContract(
        address tower_contract
    ) public virtual returns (bool) {
        require(msg.sender == owner, "Owner only");
        meca_tower_contract = MecaTowerAbstractContract(tower_contract);
        return true;
    }

    function getHostContract(
    ) public view virtual returns (address) {
        return address(meca_host_contract);
    }

    function getTaskContract(
    ) public view virtual returns (address) {
        return address(meca_task_contract);
    }

    function getTowerContract(
    ) public view virtual returns (address) {
        return address(meca_tower_contract);
    }

    function sendTask(
        address tower_address,
        address host_address,
        bytes32[2] calldata cid,
        uint256 caller_host_fee,
        uint256 input_size,
        bytes32 input_hash
    ) public payable virtual returns (bool) {
        
    }

    function getRunningTask(
        bytes32 task_id
    ) public view virtual returns (running_task memory);

    function finishTask(
        bytes32 tid
    ) public virtual returns (bool) {
        
    }

}