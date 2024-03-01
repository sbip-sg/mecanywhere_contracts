// SPDX-License-Identifier: MIT 
/*

Name: MecaSchedulerContract
Description: An on-chain Scheduler contract for MECA ecosystem
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

    function _deleteRunningTask(
        bytes32 taskId
    ) internal override
    {
        towersSize[runningTasks[taskId].towerAddress] -= runningTasks[taskId].size;
        delete runningTasks[taskId];
    }

    // Internal functions that are view

    function _getRunningTask(
        bytes32 taskId
    ) internal view override returns (RunningTask memory)
    {
        return runningTasks[taskId];
    }

    // Private functions

}