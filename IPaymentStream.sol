// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPaymentStream {
    struct Stream {
        address payer;
        address payee;
        uint256 ratePerSecond;
        uint256 depositAmount;
        uint256 balance;
        uint256 lastUpdateTimestamp;
        uint256 totalWithdrawn;
        bool isActive;
        bool isPaused;
        uint256 createdAt;
    }
    
    struct UsageRecord {
        uint256 totalUnits;
        uint256 ratePerUnit;
        uint256 totalFees;
        uint256 lastRecordedAt;
    }

    event StreamOpened(
        uint256 indexed streamId,
        address indexed payer,
        address indexed payee,
        uint256 ratePerSecond,
        uint256 depositAmount
    );
    
    event StreamUpdated(uint256 indexed streamId, uint256 newRate);
    event StreamPaused(uint256 indexed streamId);
    event StreamResumed(uint256 indexed streamId);
    event StreamClosed(uint256 indexed streamId, uint256 finalBalance);
    event Withdrawn(uint256 indexed streamId, address indexed payee, uint256 amount);
    event StreamDepleted(uint256 indexed streamId);
    event UsageRecorded(uint256 indexed streamId, uint256 units, uint256 totalFees);
}
