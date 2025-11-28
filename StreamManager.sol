// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IPaymentStream.sol";
import "./libraries/StreamMath.sol";

contract StreamManager is IPaymentStream, ReentrancyGuard, AccessControl {
    using EnumerableSet for EnumerableSet.UintSet;
    using StreamMath for uint256;
    
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    // Stream storage
    mapping(uint256 => Stream) public streams;
    mapping(uint256 => UsageRecord) public usageRecords;
    mapping(address => EnumerableSet.UintSet) private payerStreams;
    mapping(address => EnumerableSet.UintSet) private payeeStreams;
    
    uint256 private nextStreamId;
    uint256 public totalActiveStreams;
    uint256 public totalVolume;
    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }
    
    function openStream(
        address payee,
        uint256 ratePerSecond,
        uint256 depositAmount
    ) external payable nonReentrant returns (uint256 streamId) {
        StreamMath.validateStreamParameters(msg.sender, payee, ratePerSecond, depositAmount);
        require(msg.value == depositAmount, "Incorrect deposit amount");
        
        streamId = nextStreamId++;
        
        streams[streamId] = Stream({
            payer: msg.sender,
            payee: payee,
            ratePerSecond: ratePerSecond,
            depositAmount: depositAmount,
            balance: depositAmount,
            lastUpdateTimestamp: block.timestamp,
            totalWithdrawn: 0,
            isActive: true,
            isPaused: false,
            createdAt: block.timestamp
        });
        
        payerStreams[msg.sender].add(streamId);
        payeeStreams[payee].add(streamId);
        totalActiveStreams++;
        totalVolume += depositAmount;
        
        emit StreamOpened(streamId, msg.sender, payee, ratePerSecond, depositAmount);
    }
    
    function updateRate(uint256 streamId, uint256 newRatePerSecond) external {
        Stream storage stream = streams[streamId];
        require(stream.isActive, "Stream not active");
        require(msg.sender == stream.payer, "Only payer can update rate");
        require(newRatePerSecond > 0, "Invalid rate");
        
        _updateStreamBalance(streamId);
        stream.ratePerSecond = newRatePerSecond;
        
        emit StreamUpdated(streamId, newRatePerSecond);
    }
    
    function pauseStream(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        require(stream.isActive, "Stream not active");
        require(msg.sender == stream.payer, "Only payer can pause");
        require(!stream.isPaused, "Stream already paused");
        
        _updateStreamBalance(streamId);
        stream.isPaused = true;
        
        emit StreamPaused(streamId);
    }
    
    function resumeStream(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        require(stream.isActive, "Stream not active");
        require(msg.sender == stream.payer, "Only payer can resume");
        require(stream.isPaused, "Stream not paused");
        
        stream.isPaused = false;
        stream.lastUpdateTimestamp = block.timestamp;
        
        emit StreamResumed(streamId);
    }
    
    function closeStream(uint256 streamId) external nonReentrant {
        Stream storage stream = streams[streamId];
        require(stream.isActive, "Stream not active");
        require(
            msg.sender == stream.payer || msg.sender == stream.payee,
            "Not authorized"
        );
        
        _updateStreamBalance(streamId);
        
        uint256 refundAmount = stream.balance;
        if (refundAmount > 0) {
            (bool success, ) = stream.payer.call{value: refundAmount}("");
            require(success, "Refund failed");
        }
        
        _cleanupStream(streamId, stream);
        
        emit StreamClosed(streamId, refundAmount);
    }
    
    function withdrawAvailable(uint256 streamId) external nonReentrant returns (uint256 withdrawnAmount) {
        Stream storage stream = streams[streamId];
        require(stream.isActive, "Stream not active");
        require(msg.sender == stream.payee, "Only payee can withdraw");
        require(!stream.isPaused, "Stream is paused");
        
        (uint256 owed, bool isDepleted) = _updateStreamBalance(streamId);
        require(owed > 0, "No funds available");
        
        stream.totalWithdrawn += owed;
        withdrawnAmount = owed;
        
        (bool success, ) = stream.payee.call{value: owed}("");
        require(success, "Withdrawal failed");
        
        if (isDepleted) {
            _cleanupStream(streamId, stream);
            emit StreamDepleted(streamId);
        }
        
        emit Withdrawn(streamId, msg.sender, owed);
    }
    
    function getAvailableBalance(uint256 streamId) external view returns (uint256 available) {
        Stream memory stream = streams[streamId];
        if (!stream.isActive || stream.isPaused) {
            return 0;
        }
        
        (uint256 owed,,) = StreamMath.calculateOwedAmount(
            stream.lastUpdateTimestamp,
            block.timestamp,
            stream.ratePerSecond,
            stream.balance
        );
        
        return owed;
    }
    
    function getStream(uint256 streamId) external view returns (Stream memory) {
        return streams[streamId];
    }
    
    function getStreamsByPayer(address payer) external view returns (uint256[] memory) {
        return payerStreams[payer].values();
    }
    
    function getStreamsByPayee(address payee) external view returns (uint256[] memory) {
        return payeeStreams[payee].values();
    }
    
    function _updateStreamBalance(uint256 streamId) internal returns (uint256 owed, bool isDepleted) {
        Stream storage stream = streams[streamId];
        
        (owed, stream.balance, isDepleted) = StreamMath.calculateOwedAmount(
            stream.lastUpdateTimestamp,
            block.timestamp,
            stream.ratePerSecond,
            stream.balance
        );
        
        stream.lastUpdateTimestamp = block.timestamp;
        
        if (isDepleted) {
            stream.isActive = false;
        }
    }
    
    function _cleanupStream(uint256 streamId, Stream storage stream) internal {
        stream.isActive = false;
        payerStreams[stream.payer].remove(streamId);
        payeeStreams[stream.payee].remove(streamId);
        totalActiveStreams--;
    }
}
