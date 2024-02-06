// SPDX-License-Identifier: MIT 
/*

Name: MecaDaoContract
Description: An on-chain DAO contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;


import "./SchedulerAbstract.sol";

contract MecaDaoContract
{
	address payable owner;

    MecaSchedulerAbstractContract meca_scheduler_contract;

    constructor() { owner = payable(msg.sender); }
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function setSchedulerContract(
        address scheduler_contract
    ) public onlyOwner returns (bool) {
        meca_scheduler_contract = MecaSchedulerAbstractContract(scheduler_contract);
        return true;
    }

    function getSchedulerContract(
    ) public view returns (address) {
        return address(meca_scheduler_contract);
    }

}
