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
    
    mapping(bytes32 => running_task) public running_tasks;
    mapping(address => uint256) public towers_size;
    mapping(address => uint256) public hosts_end_block;
    mapping(address => uint256) public hosts_nonce;

    // TODO: add a schedule flag for the contract
    // so we can stop geetting tasks before we
    // want to clear the contract
    // transform task tasks in an array
    // add a host array so we can clear the contract

    uint256 public constant SCHEDULER_FEE = 1 wei;

    constructor() MecaSchedulerAbstractContract()
    {
    }

    function clear() public override
    {
        require(msg.sender == owner, "Owner only");
        meca_host_contract = MecaHostAbstractContract(address(0));
        meca_task_contract = MecaTaskAbstractContract(address(0));
        meca_tower_contract = MecaTowerAbstractContract(address(0));
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function sendTask(
        address tower_address,
        address host_address,
        bytes32 task_ipfs_sha256,
        uint256 caller_host_fee,
        uint256 input_size,
        bytes32 input_hash
    ) public payable override returns (bool)
    {
        // compute the fees and check if the caller has enough funds
        uint256 task_fee = meca_task_contract.getTaskFee(task_ipfs_sha256);
        uint256 task_size = meca_task_contract.getTaskSize(task_ipfs_sha256);
        uint256 task_block_timeout = meca_host_contract.getTaskBlockTimeout(host_address, task_ipfs_sha256);
        uint256 tower_fee = meca_tower_contract.getTowerFee(tower_address, task_size, task_block_timeout);
        uint256 host_task_fee_type = meca_host_contract.getTaskFeeType(host_address, task_ipfs_sha256);
        uint256 host_fee = 0;
        if (host_task_fee_type == 0) {
            host_fee = meca_host_contract.getTaskFeeContract(host_address, task_ipfs_sha256).getFee();
        } else if (host_task_fee_type == 1) {
            host_fee = meca_host_contract.getTaskFeeContract(host_address, task_ipfs_sha256).getFeeSize(input_size);
        } else if (host_task_fee_type == 2) {
            host_fee = caller_host_fee;
        } else {
            revert("Unkown host_task_fee_type");
        }

        uint256 insurance_fee = (task_fee + host_fee + tower_fee) / 10;
        uint256 total_fee = task_fee + host_fee + tower_fee + SCHEDULER_FEE + insurance_fee;

        require(msg.value >= total_fee, "Insufficient funds");

        // compute if the tower + host are a good match
        uint256 tower_size_limit = meca_tower_contract.getTowerSizeLimit(tower_address);
        uint256 host_block_timeout_limit = meca_host_contract.getHostBlockTimeoutLimit(host_address);

        uint256 host_end_block = hosts_end_block[host_address];
        if (host_end_block < block.number) {
            host_end_block = block.number;
        }

        require(host_end_block + task_block_timeout <= block.number + host_block_timeout_limit, "Host block timeout limit exceeded");
        hosts_end_block[host_address] = host_end_block + task_block_timeout;

        uint256 tower_size = towers_size[tower_address];
        require(tower_size + task_size <= tower_size_limit, "Tower size limit exceeded");
        towers_size[tower_address] = tower_size + task_size;

        // create the running task
        // compute the task id as keccak of information
        bytes32 task_id = keccak256(
            abi.encodePacked(
                tower_address,
                host_address,
                task_ipfs_sha256,
                input_hash,
                hosts_nonce[host_address]
        ));
        hosts_nonce[host_address] = hosts_nonce[host_address] + 1;

        // make the task
        running_tasks[task_id] = running_task({
            ipfs_sha256: task_ipfs_sha256,
            input_hash: input_hash,
            size: task_size,
            tower_address: tower_address,
            host_address: host_address,
            owner: msg.sender,
            start_block: block.number,
            block_timeout_limit: task_block_timeout,
                fee: running_task_fee({
                    task_fee: task_fee,
                    host_fee: host_fee,
                    scheduler_fee: SCHEDULER_FEE,
                    tower_fee: tower_fee,
                    insurance_fee: insurance_fee
                })
            });
        
        return true;
    }

    function getRunningTask(
        bytes32 task_id
    ) public view override returns (running_task memory)
    {
        return running_tasks[task_id];
    }

    function finishTask(
        bytes32 task_id
    ) public override returns (bool)
    {
        running_task memory task = running_tasks[task_id];
        require(task.owner == msg.sender, "Owner only");
        //require(task.start_block + task.block_timeout_limit >= block.number, "Task timeout limit exceeded");

        // pay the fees
        payable(task.tower_address).transfer(task.fee.tower_fee);
        payable(task.host_address).transfer(task.fee.host_fee);
        payable(owner).transfer(task.fee.insurance_fee);
        address task_owner = meca_task_contract.getTaskOwner(task.ipfs_sha256);
        payable(task_owner).transfer(task.fee.task_fee);

        // remove the task
        delete running_tasks[task_id];

        // update the tower size
        towers_size[task.tower_address] -= task.size;

        return true;
    }
}