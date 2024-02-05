// SPDX-License-Identifier: MIT 
/*

Name: MecaTowerContract
Description: An on-chain Tower contract for MECA ecosystem
Author: Ciocirlan Stefan-Dan (sdcioc)
Date: Feb 2024

MIT License

*/

pragma solidity ^0.8.17;

import "./TowerAbstract.sol";

contract MecaTaskContract is MecaTowerAbstractContract
{
    // We have a list with all the tower and a mapping to check if a tower exists
    // and what is the position in the list of a tower (if it exists is index + 1, if not is 0)
    mapping(address => uint32) public towers_index;
    tower[] public towers;

    mapping(address => address[]) public tower_pending_hosts;
    mapping(address => address[]) public tower_active_hosts;

    constructor() MecaTowerAbstractContract()
    {
    }

    function registerTower(
        uint256 size_limit,
        string calldata public_connection,
        uint256 fee,
        uint8 fee_type
    ) public payable override returns (bool)
    {
        if (towers_index[msg.sender] != 0) {
            revert();
        }
        towers.push(
            tower(
                msg.sender,
                size_limit,
                public_connection,
                fee_type,
                fee,
                msg.value
            )
        );

        towers_index[msg.sender] = uint32(towers.length);
        tower_active_hosts[msg.sender] = new address[](0);
        tower_pending_hosts[msg.sender] = new address[](0);
        return true;
    }

    function deleteTower(
        address tower_address
    ) public override returns (bool)
    {
        uint32 index = towers_index[tower_address];
        if (index == 0) {
            return false;
        }
        tower memory t = towers[index - 1];
        towers[index - 1] = towers[towers.length - 1];
        towers_index[towers[towers.length  - 1].owner] = index;
        towers_index[t.owner] = 0;
        towers.pop();
        tower_active_hosts[t.owner] = new address[](0);
        tower_pending_hosts[t.owner] = new address[](0);
        if (t.owner != msg.sender) {
            revert();
        }
        if (t.stake > 0) {
            payable(msg.sender).transfer(t.stake);
        }
        return true;
    }

    function addStake(
    ) public payable override returns (bool)
    {
        uint32 index = towers_index[msg.sender];
        if (index == 0) {
            revert();
        }
        towers[index - 1].stake += msg.value;
        return true;
    }

    function updateTowerFee(
        uint256 fee,
        uint8 fee_type
    ) public override returns (bool)
    {
        uint32 index = towers_index[msg.sender];
        if (index == 0) {
            revert();
        }
        towers[index - 1].fee = fee;
        towers[index - 1].fee_type = fee_type;
        return true;
    }

    function getTowers(
    ) public view override returns (tower[] memory)
    {
        return towers;
    }

    function getTowerFee(
        address tower_address,
        uint256 size,
        uint256 block_timeout_limit
    ) public view override returns (uint256)
    {
        uint32 index = towers_index[tower_address];
        if (index == 0) {
            revert();
        }
        if (towers[index - 1].fee_type == 0) {
            return towers[index - 1].fee;
        } else if (towers[index - 1].fee_type == 1) {
            return towers[index - 1].fee * size;
        } else if (towers[index - 1].fee_type == 2) {
            return towers[index - 1].fee * block_timeout_limit;
        } else if (towers[index - 1].fee_type == 3) {
            return towers[index - 1].fee * size * block_timeout_limit;
        } else {
            return 0;
        }
    }

    function getTowerSizeLimit(
        address tower_address
    ) public view override returns (uint256)
    {
        uint32 index = towers_index[tower_address];
        if (index == 0) {
            revert();
        }
        return towers[index - 1].size_limit;
    }

    function getTowerPublicConnection(
        address tower_address
    ) public view override returns (string memory)
    {
        uint32 index = towers_index[tower_address];
        if (index == 0) {
            revert();
        }
        return towers[index - 1].public_connection;
    }

    function getTowerStake(
        address tower_address
    ) public view override returns (uint256)
    {
        uint32 index = towers_index[tower_address];
        if (index == 0) {
            revert();
        }
        return towers[index - 1].stake;
    }

    function registerMeForTower(
        address tower_address
    ) public override returns (bool)
    {
        tower_pending_hosts[tower_address].push(msg.sender);
        return true;
    }

    function acceptHost(
        address host_address
    ) public override returns (bool)
    {
        uint32 index = towers_index[msg.sender];
        if (index == 0) {
            revert();
        }
        for (uint256 i = 0; i < tower_pending_hosts[msg.sender].length; i++) {
            if (tower_pending_hosts[msg.sender][i] == host_address) {
                tower_active_hosts[msg.sender].push(host_address);
                tower_pending_hosts[msg.sender][i] = tower_pending_hosts[msg.sender][tower_pending_hosts[msg.sender].length - 1];
                tower_pending_hosts[msg.sender].pop();
                return true;
            }
        }
        return false;
    }

    function deleteHost(
        address host_address
    ) public override returns (bool)
    {
        uint32 index = towers_index[msg.sender];
        if (index == 0) {
            revert();
        }
        for (uint256 i = 0; i < tower_active_hosts[msg.sender].length; i++) {
            if (tower_active_hosts[msg.sender][i] == host_address) {
                tower_active_hosts[msg.sender][i] = tower_active_hosts[msg.sender][tower_active_hosts[msg.sender].length - 1];
                tower_active_hosts[msg.sender].pop();
                return true;
            }
        }
        return false;
    }

    function getTowerHosts(
        address tower_address
    ) public view override returns (address[] memory)
    {
        return tower_active_hosts[tower_address];
    }

    function getTowerPendingHosts(
        address tower_address
    ) public view override returns (address[] memory)
    {
        return tower_pending_hosts[tower_address];
    }

    function deleteTowerPendingHosts(
    ) public override returns (bool)
    {
        tower_pending_hosts[msg.sender] = new address[](0);
        return true;
    }
}