// SPDX-License-Identifier: MIT 
/*

Name: MecaSchedulerContract
Description: An on-chain Scheduler contract for MECAnywhere ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./SchedulerAbstract.sol";

contract MecaSchedulerContract is MecaSchedulerAbstractContract
{
    /// The running tasks map of taskId to running task
    mapping(bytes32 => RunningTask) public runningTasks;
    /// The Tower size map of towerAddress to size
    mapping(address => uint256) public towersSize;
    /// The end block of the hosts map of hostAddress to endBlock
    mapping(address => uint256) public hostsEndBlock;
    /// the tee task information
    mapping(bytes32 => TeeTask) public teeTasks;

    // custom modifiers

    // constructor
    constructor(
        uint256 schedulerFee
    ) MecaSchedulerAbstractContract(schedulerFee)
    {
    }

    // External functions

    // External functions that are view
    
    // External functions that are pure

    // Public functions

    function getHostFirstAvailableBlock(
        address hostAddress
    ) public view override returns (uint256)
    {
        uint256 hostFirstAvailableBlock = hostsEndBlock[hostAddress];
        if (hostFirstAvailableBlock < block.number) {
            hostFirstAvailableBlock = block.number;
        }
        return hostFirstAvailableBlock;
    }

    function getTowerCurrentSize(
        address towerAddress
    ) public view override returns (uint256)
    {
        return towersSize[towerAddress];
    }

    // Internal functions

    function _clear() internal override
    {
    }

    function _addRunningTask(
        bytes32 taskId,
        RunningTask memory runningTask
    ) internal override
    {
        runningTasks[taskId] = runningTask;
        towersSize[runningTasks[taskId].towerAddress] += runningTasks[taskId].size;
    }

    function _registerTaskOutput(
        bytes32 taskId,
        bytes32 outputHash
    ) internal override
    {
        runningTasks[taskId].outputHash = outputHash;
    }

    function _registerTeeTaskInitialInputHash(
        bytes32 taskId,
        bytes32 initialInputHash
    ) internal override
    {
        if (teeTasks[taskId].initialInputHash != 0) {
            revert();
        }
        teeTasks[taskId].initialInputHash = initialInputHash;
    }

    function _registerTeeTaskEncryptedInput(
        bytes32 taskId,
        bytes32 encryptedInputHash
    ) internal override
    {
        if (teeTasks[taskId].encryptedInputHash != 0) {
            revert();
        }
        teeTasks[taskId].encryptedInputHash = encryptedInputHash;
    }


    function _deleteRunningTask(
        bytes32 taskId
    ) internal override
    {
        towersSize[runningTasks[taskId].towerAddress] -= runningTasks[taskId].size;
        delete runningTasks[taskId];
    }


    function _deleteTeeTask(
        bytes32 taskId
    ) internal override
    {
        delete teeTasks[taskId];
    }

    // Internal functions that are view

    function _getRunningTask(
        bytes32 taskId
    ) internal view override returns (RunningTask memory)
    {
        return runningTasks[taskId];
    }

    function _getTeeTask(
        bytes32 taskId
    )
        internal
        view
        override
        returns (TeeTask memory)
    {
        return teeTasks[taskId];
    }
    // Private functions

}