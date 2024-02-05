// SPDX-License-Identifier: MIT 
/*

Name: MecaDaoContract
Description: An on-chain DAO contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

contract MecaDaoContract
{
    event LogTaskContractUpdate(address task_contract);
    event LogTowerContractUpdate(address tower_contract);
    event LogHostContractUpdate(address host_contract);
    event LogSchedulerContractUpdate(address scheduler_contract);

	address public owner;
    address public meca_task_contract;
    address public meca_tower_contract;
    address public meca_host_contract;
    address public meca_scheduler_contract;

	constructor() 
	{
		owner = msg.sender;
        meca_host_contract = address(0);
        meca_task_contract = address(0);
        meca_tower_contract = address(0);
        meca_scheduler_contract = address(0);
    }

    function setHostContract(address host_contract) public
    {
        require(msg.sender == owner, "Owner only");
        meca_host_contract = host_contract;
        emit LogHostContractUpdate(host_contract);
    }

    function setTaskContract(address task_contract) public
    {
        require(msg.sender == owner, "Owner only");
        meca_task_contract = task_contract;
        emit LogTaskContractUpdate(task_contract);
    }

    function setTowerContract(address tower_contract) public
    {
        require(msg.sender == owner, "Owner only");
        meca_tower_contract = tower_contract;
        emit LogTowerContractUpdate(tower_contract);
    }

    function setSchedulerContract(address scheduler_contract) public
    {
        require(msg.sender == owner, "Owner only");
        meca_scheduler_contract = scheduler_contract;
        emit LogSchedulerContractUpdate(scheduler_contract);
    }

}
