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
    /// The owner of the contract
    address payable public owner;
    /// The scheduler fee
    uint256 immutable public SCHEDULER_FEE;
    /// The host contract
    MecaHostAbstractContract internal hostContract;
    /// The task contract
    MecaTaskAbstractContract internal taskContract;
    /// The tower contract
    MecaTowerAbstractContract internal towerContract;
    /// The scheduler nonce
    uint256 public schedulerNonce;
    /// The scheduler flag
    bool public schedulerFlag;

    /**
    * @notice The RunningTaskFee structure
    * @param tower The tower fee
    * @param host The host fee
    * @param scheduler The scheduler fee
    * @param task The task fee
    * @param insurance The insurance fee
    */
    struct RunningTaskFee 
    {
        uint256 tower;
        uint256 host;
        uint256 scheduler;
        uint256 task;
        uint256 insurance;
    }

    /**
    * @notice The RunningTask structure
    * @param ipfsSha256 The IPFS hash of the task
    * @param inputHash The input hash of the task
    * @param outputHash The output hash of the task
    * @param size The size of the task
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    * @param owner The owner of the task
    * @param startBlock The start block of the task
    * @param blockTimeout The block timeout of the task
    * @param fee The fee of the task
    */
    struct RunningTask {
        bytes32 ipfsSha256;
        bytes32 inputHash;
        bytes32 outputHash;
        uint256 size;
        address towerAddress;
        address hostAddress;
        address owner;
        uint256 startBlock;
        uint256 blockTimeout;
        RunningTaskFee fee;
    }

    /**
    * @notice The TeeTask structure
    * @param encryptedInputHash The hash of the encrypted input of the task
    * @param enclavePublicKey The public key of the enclave
    */
    struct TeeTask {
        bytes32 encryptedInputHash;
        bytes32[2] enclavePublicKey;
    }

    event TaskSent(
        bytes32 taskId,
        address sender
    );

    // custom modifiers
    /**
    * @notice The onlyOwner modifier
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only");
        _;
    }
    /**
    * @notice The hasFee modifier
    */
    modifier hasFee() {
        require(msg.value == SCHEDULER_FEE, "Minimum fee required");
        _;
    }
    /**
    * @notice activeScheduler modifier
    */
    modifier activeScheduler() {
        require(schedulerFlag, "Scheduler not active");
        _;
    }

    // TODO: add a modifier for all task over

    /**
    * @notice The constructor
    * @param schedulerFee The fee for the scheduler
    */
    constructor(
        uint256 schedulerFee
    ) {
        owner = payable(tx.origin);
        SCHEDULER_FEE = schedulerFee;
        hostContract = MecaHostAbstractContract(payable(address(0)));
        taskContract = MecaTaskAbstractContract(payable(address(0)));
        towerContract = MecaTowerAbstractContract(payable(address(0)));
        schedulerNonce = 0;
        schedulerFlag = false;
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

    /**
    * @notice The clear function
    * @dev This function is used to clear the contract
    */
    function clear() external onlyOwner {
        _clear();
    }

    // External functions

    /**
    * @notice The setHostContract function
    * @param newAddress The new host contract address
    */
    function setHostContract(
        address newAddress
    )
        external
        onlyOwner
    {
        hostContract = MecaHostAbstractContract(payable(newAddress));
    }

    /**
    * @notice The setTaskContract function
    * @param newAddress The new task contract address
    */
    function setTaskContract(
        address newAddress
    )
        external
        onlyOwner
    {
        taskContract = MecaTaskAbstractContract(payable(newAddress));
    }

    /**
    * @notice The setTowerContract function
    * @param newAddress The new tower contract address
    */
    function setTowerContract(
        address newAddress
    )
        external
        onlyOwner
    {
        towerContract = MecaTowerAbstractContract(payable(newAddress));
    }

    /**
    * @notice The setSchedulerFlag function
    * @param newSchedulerFlag The new scheduler flag
    */
    function setSchedulerFlag(
        bool newSchedulerFlag
    )
        external
        onlyOwner
    {
        schedulerFlag = newSchedulerFlag;
    }

    /**
    * @notice Send a task to the scheduler
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param inputHash The hash of the input
    */
    function sendTask(
        address towerAddress,
        address hostAddress,
        bytes32 ipfsSha256,
        bytes32 inputHash
    )
        external
        payable
        activeScheduler
    {
        
        uint256 taskSize = taskContract.getTaskSize(ipfsSha256);
        uint256 taskBlockTimeout = hostContract.getTaskBlockTimeout(
            hostAddress,
            ipfsSha256
        );

        RunningTaskFee memory runningTaskFee = _getRunningTaskFee(
            towerAddress,
            hostAddress,
            ipfsSha256,
            taskSize,
            taskBlockTimeout
        );

        uint256 towerSizeLimit = towerContract.getTowerSizeLimit(
            towerAddress
        );
        uint256 hostBlockTimeoutLimit = hostContract.getHostBlockTimeoutLimit(
            hostAddress
        );

        uint256 hostFirstAvailableBlock = getHostFirstAvailableBlock(
            hostAddress
        );

        require(
            (hostFirstAvailableBlock + taskBlockTimeout) <= (block.number + hostBlockTimeoutLimit),
            "Host block timeout limit exceeded"
        );

        uint256 usedTowerSize = getTowerCurrentSize(towerAddress);

        require(
            (usedTowerSize + taskSize) <= towerSizeLimit,
            "Tower size limit exceeded"
        );

        bytes32 taskId = keccak256(
            abi.encodePacked(
                towerAddress,
                hostAddress,
                ipfsSha256,
                inputHash,
                schedulerNonce
            )
        );

        schedulerNonce += 1;

        RunningTask memory runningTask = RunningTask({
            ipfsSha256: ipfsSha256,
            inputHash: inputHash,
            outputHash: bytes32(0),
            size: taskSize,
            towerAddress: towerAddress,
            hostAddress: hostAddress,
            owner: msg.sender,
            startBlock: hostFirstAvailableBlock,
            blockTimeout: taskBlockTimeout,
            fee: runningTaskFee
        });

        _addRunningTask(
            taskId,
            runningTask
        );

        emit TaskSent(
            taskId,
            msg.sender
        );
    }

    /**
    * @notice Finish a task
    * @param taskId The ID of the task
    */
    function finishTask(
        bytes32 taskId
    )
        external
    {
        RunningTask memory runningTask = _getRunningTask(taskId);
        require(
            block.number > (runningTask.startBlock + runningTask.blockTimeout),
            "Task not over"
        );
        require(
            msg.sender == runningTask.owner,
            "Only the owner can finish the task"
        );
        if (runningTask.outputHash == bytes32(0)) {
            // not output register from the host
            _deleteRunningTask(taskId);
            uint256 totalFee = (
                runningTask.fee.insurance +
                runningTask.fee.tower +
                runningTask.fee.host +
                runningTask.fee.task
            );
            payable(msg.sender).transfer(
                totalFee
            );
            towerContract.unregisterTowerHost(
                runningTask.towerAddress,
                runningTask.hostAddress
            );
        } else {
            _deleteRunningTask(taskId);
            payable(runningTask.towerAddress).transfer(runningTask.fee.tower);
            payable(runningTask.hostAddress).transfer(runningTask.fee.host);
            payable(msg.sender).transfer(runningTask.fee.insurance);
            address taskOwner = taskContract.getTaskOwner(
                runningTask.ipfsSha256
            );
            payable(taskOwner).transfer(runningTask.fee.task);
        }
    }

    /**
    * @notice Register the output of a task
    * @param taskId The ID of the task
    * @param outputHash The hash of the output
    */
    function registerTaskOutput(
        bytes32 taskId,
        bytes32 outputHash
    )
        external
    {
        RunningTask memory runningTask = _getRunningTask(taskId);
        require(block.number <= (runningTask.startBlock + runningTask.blockTimeout), "Task last block passed over");
        require(
            msg.sender == runningTask.hostAddress,
            "Only the host can register the output"
        );
        _registerTaskOutput(taskId, outputHash);
    }


    function wrongInputHash(
        bytes32 taskId
    )
        external
    {
        RunningTask memory runningTask = _getRunningTask(taskId);
        require(
            block.number <= (
                runningTask.startBlock + runningTask.blockTimeout
            ),
            "Task last block passed over"
        );
        require(
            msg.sender == runningTask.hostAddress,
            "Only the host can register a wrong input hash"
        );
        _deleteRunningTask(taskId);
        uint256 totalFee = (
            runningTask.fee.insurance +
            runningTask.fee.tower +
            runningTask.fee.host +
            runningTask.fee.task
        );
        payable(runningTask.owner).transfer(
            totalFee
        );
    }

    /**
    * @notice Register the enclave public key of a task
    * @param taskId The ID of the task
    * @param enclavePublicKey The public key of the enclave
    */
    function registerTeeTaskPubKey(
        bytes32 taskId,
        bytes32[2] calldata enclavePublicKey
    )
        external
    {
        RunningTask memory runningTask = _getRunningTask(taskId);
        require(
            block.number <= (
                runningTask.startBlock + runningTask.blockTimeout
            ),
            "Task last block passed over"
        );
        require(
            msg.sender == runningTask.hostAddress,
            "Only the host can register the enclave public key"
        );
        _registerTeeTaskPubKey(
            taskId,
            enclavePublicKey
        );
    }

    /**
    * @notice Register the encrypted input of a task
    * @param taskId The ID of the task
    * @param encryptedInputHash The hash of the encrypted input
    */
    function registerTeeTaskEncryptedInput(
        bytes32 taskId,
        bytes32 encryptedInputHash
    )
        external
    {
        RunningTask memory runningTask = _getRunningTask(taskId);
        require(
            block.number <= (
                runningTask.startBlock + runningTask.blockTimeout
            ),
            "Task last block passed over"
        );
        require(
            msg.sender == runningTask.owner,
            "Only the owner can register the encrypted input"
        );
        _registerTeeTaskEncryptedInput(
            taskId,
            encryptedInputHash
        );
    }

    // External functions that are view
    
    /**
    * @notice Get the host contract
    */
    function getHostContract() external view returns (address) {
        return address(hostContract);
    } 

    /**
    * @notice Get the task contract
    */
    function getTaskContract() external view returns (address) {
        return address(taskContract);
    }

    /**
    * @notice Get the tower contract
    */
    function getTowerContract() external view returns (address) {
        return address(towerContract);
    }

    /**
    * @notice Get the running task
    * @param taskId The ID of the task
    * @return RunningTask The running task
    */
    function getRunningTask(
        bytes32 taskId
    )
        external
        view
        returns (RunningTask memory)
    {
        return _getRunningTask(taskId);
    }
    

    /**
    * @notice Get the running task
    * @param taskId The ID of the task
    * @return TeeTask The tee task information
    */
    function getTeeTask(
        bytes32 taskId
    )
        external
        view
        returns (TeeTask memory)
    {
        return _getTeeTask(taskId);
    }
    // External functions that are pure

    // Public functions

    /**
    * @notice Get the host first available block
    * @param hostAddress The address of the host
    * @return uint256 The first available block
    */
    function getHostFirstAvailableBlock(
        address hostAddress
    )
        public
        view
        virtual
        returns (uint256);
    

    /**
    * @notice Get the tower current size
    * @param towerAddress The address of the tower
    * @return uint256 The current size of the tower
    */
    function getTowerCurrentSize(
        address towerAddress
    )
        public
        view
        virtual
        returns (uint256);

    // Internal functions

    /**
    * @notice The clear function
    */
    function _clear() internal virtual;

    /**
    * @notice Get the running fee
    * @param towerAddress The address of the tower
    * @param hostAddress The address of the host
    * @param ipfsSha256 The IPFS hash of the task
    * @param taskSize The size of the task
    * @param taskBlockTimeout The block timeout of the task
    * @return RunningTaskFee The running task fee
    */
    function _getRunningTaskFee(
        address towerAddress,
        address hostAddress,
        bytes32 ipfsSha256,
        uint256 taskSize,
        uint256 taskBlockTimeout
    )
        internal
        returns (RunningTaskFee memory)
    {
        uint256 taskFee = taskContract.getTaskFee(ipfsSha256);
        uint256 towerFee = towerContract.getTowerFee(
            towerAddress,
            taskSize,
            taskBlockTimeout
        );
        uint256 hostFee = hostContract.getTaskFee(
            hostAddress,
            ipfsSha256
        );
        uint256 insuranceFee = (taskFee + hostFee + towerFee) / 10;
        uint256 totalFee = taskFee + hostFee + towerFee + SCHEDULER_FEE + insuranceFee;
        require(msg.value == totalFee, "Wrong funds");

        RunningTaskFee memory runningTaskFee = RunningTaskFee({
            tower: towerFee,
            host: hostFee,
            scheduler: SCHEDULER_FEE,
            task: taskFee,
            insurance: insuranceFee
        });

        return runningTaskFee;

    }

    /**
    * @notice The addRunningTask function
    * @param taskId The ID of the task
    * @param runningTask The running task
    */
    function _addRunningTask(
        bytes32 taskId,
        RunningTask memory runningTask
    )
        internal
        virtual;
    

    /**
    * @notice The registerOutput function
    * @param taskId The ID of the task
    * @param outputHash The hash of the output
    */
    function _registerTaskOutput(
        bytes32 taskId,
        bytes32 outputHash
    )
        internal
        virtual;

    /**
    * @notice The registerTeeTaskPubKey function
    * @param taskId The ID of the task
    * @param enclavePublicKey The public key of the enclave
    */
    function _registerTeeTaskPubKey(
        bytes32 taskId,
        bytes32[2] calldata enclavePublicKey
    )
        internal
        virtual;
    
    /**
    * @notice The registerTeeTaskEncryptedInput function
    * @param taskId The ID of the task
    * @param encryptedInputHash The hash of the encrypted input
    */
    function _registerTeeTaskEncryptedInput(
        bytes32 taskId,
        bytes32 encryptedInputHash
    )
        internal
        virtual;

    /**
    * @notice The deleteRunningTask function
    * @param taskId The ID of the task
    */
    function _deleteRunningTask(
        bytes32 taskId
    )
        internal
        virtual;

    /**
    * @notice The deleteTeeTask function
    * @param taskId The ID of the task
    */
    function _deleteTeeTask(
        bytes32 taskId
    )
        internal
        virtual;
    // Internal functions that are view

    /**
    * @notice Get the running task
    * @param taskId The ID of the task
    * @return RunningTask The running task
    */
    function _getRunningTask(
        bytes32 taskId
    )
        internal
        view
        virtual
        returns (RunningTask memory);

    /**
    * @notice Get the running task
    * @param taskId The ID of the task
    * @return TeeTask The tee task information
    */
    function _getTeeTask(
        bytes32 taskId
    )
        internal
        view
        virtual
        returns (TeeTask memory);

    // Private functions

}