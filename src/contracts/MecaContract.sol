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
    /// The owner of the contract
	address payable public owner;
    /// The scheduler contract
    MecaSchedulerAbstractContract schedulerContract;

    // custom modifiers
    /**
    * @notice The onlyOwner modifier
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }

    // constructor
    constructor() {
        owner = payable(msg.sender);
        schedulerContract = MecaSchedulerAbstractContract(payable(address(0)));
    }

    // receive function

    /**
    * @notice The receive function
    */
    receive() external payable {
        revert();
    }

    // fallback function

    /**
    * @notice The fallback function
    */
    fallback() external payable {
        revert();
    }

    // External functions

    /**
    * @notice The clear function
    */
    function clear() external onlyOwner {
        schedulerContract = MecaSchedulerAbstractContract(
            payable(address(0))
        );
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /**
    * @notice The setSchedulerContract function
    * @param newSchedulerContract The new scheduler contract
    */
    function setSchedulerContract(
        address newSchedulerContract
    ) external onlyOwner {
        schedulerContract = MecaSchedulerAbstractContract(
            payable(newSchedulerContract)
        );
    }

    // External functions that are view

    /**
    * @notice The getSchedulerContract function
    * @return address The scheduler contract adddress
    */
    function getSchedulerContract() external view returns (address) {
        return address(schedulerContract);
    }
    
    // External functions that are pure

    // Public functions

    // Internal functions

    // Internal functions that are view

    // Private functions



}
