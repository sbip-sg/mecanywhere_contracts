// SPDX-License-Identifier: MIT 
/*

Name: MecaHostContract
Description: An on-chain Host contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./HostAbstract.sol";

contract MecaHostContract is MecaHostAbstractContract
{
    // host -> cid -> task_fees
    mapping(address => mapping(bytes32 => mapping(bytes32 => host_task)))tasks_fees;

    // We have a list with all the hosts and a mapping to check if a host exists
    // and what is the position in the list of a host (if it exists is index + 1, if not is 0)
    mapping(address => uint32) public hosts_index;
    host[] public hosts;

    constructor() MecaHostAbstractContract()
    {
    }

    function registerHost(
        bytes[] calldata public_key,
        uint8 public_key_type,
        uint256 block_timeout_limit
    ) public payable override returns (bool)
    {
        if (hosts_index[msg.sender] != 0) {
            return false;
        }
        hosts.push(
            host(
                msg.sender,
                public_key,
                public_key_type,
                block_timeout_limit,
                msg.value
            )
        );
        hosts_index[msg.sender] = uint32(hosts.length);
        return true;
    }

    function addStake(
    ) public payable override returns (bool)
    {
        uint32 index = hosts_index[msg.sender];
        if (index == 0) {
            revert();
        }
        hosts[index - 1].stake += msg.value;
        return true;
    }

    function getHostPublicKey(
        address host_address
    ) public view override returns (bytes[] memory, uint8)
    {
        uint32 index = hosts_index[host_address];
        if (index == 0) {
            return (new bytes[](0), 0);
        }
        return (hosts[index - 1].public_key, hosts[index - 1].public_key_type);
    }

    function getHostBlockTimeoutLimit(
        address host_address
    ) public view override returns (uint256)
    {
        uint32 index = hosts_index[host_address];
        if (index == 0) {
            return 0;
        }
        return hosts[index - 1].block_timeout_limit;
    }

    function getTaskFeeContract(
        address host_address,
        bytes32[2] calldata cid
    ) public view override returns (MecaTaskFee)
    {
        return tasks_fees[host_address][cid[0]][cid[1]].task_fee_contract;
    }

    function getTaskBlockTimeout(
        address host_address,
        bytes32[2] calldata cid
    ) public view override returns (uint256)
    {
        return tasks_fees[host_address][cid[0]][cid[1]].block_timeout;
    }

    function setTaskFeeContract(
        bytes32[2] calldata cid,
        MecaTaskFee task_fee_contract
    ) public override returns (bool)
    {
        if (tasks_fees[msg.sender][cid[0]][cid[1]].block_timeout == 0) {
            revert();
        }
        tasks_fees[msg.sender][cid[0]][cid[1]].task_fee_contract = task_fee_contract;
        return true;
    }

    function setTaskBlockTimeout(
        bytes32[2] calldata cid,
        uint256 block_timeout
    ) public override returns (bool)
    {
        tasks_fees[msg.sender][cid[0]][cid[1]].block_timeout = block_timeout;
        return true;
    }

    function deleteTask(
        bytes32[2] calldata cid
    ) public override returns (bool)
    {
        delete tasks_fees[msg.sender][cid[0]][cid[1]];
        return true;
    }

    function getHosts(
    ) public view override returns (host[] memory)
    {
        return hosts;
    }

    function updateBlockTimeoutLimit(
        address host_address,
        uint256 block_timeout_limit
    ) public override returns (bool)
    {
        uint32 index = hosts_index[host_address];
        if (index == 0) {
            return false;
        }
        hosts[index - 1].block_timeout_limit = block_timeout_limit;
        return true;
    }

    function updateHostPublicKey(
        address host_address,
        bytes[] calldata public_key,
        uint8 public_key_type
    ) public override returns (bool)
    {
        uint32 index = hosts_index[host_address];
        if (index == 0) {
            return false;
        }
        hosts[index - 1].public_key = public_key;
        hosts[index - 1].public_key_type = public_key_type;
        return true;
    }

    function deleteHost(
        address host_address
    ) public override returns (bool)
    {
        uint32 index = hosts_index[host_address];
        if (index == 0) {
            return false;
        }
        uint256 to_pay = hosts[index - 1].stake;
        hosts[index - 1] = hosts[hosts.length - 1];
        hosts_index[hosts[index - 1].owner] = index;
        hosts_index[host_address] = 0;
        hosts.pop();
        payable(host_address).transfer(to_pay);
        return true;
    }
}