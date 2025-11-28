// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./StreamManager.sol";

contract BatchSettler is ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    
    StreamManager public streamManager;
    
    event BatchSettled(
        address indexed settler,
        uint256[] streamIds,
        uint256 totalWithdrawn,
        uint256 gasUsed
    );
    
    constructor(address streamManagerAddress) {
        streamManager = StreamManager(streamManagerAddress);
    }
    
    function batchSettle(uint256[] calldata streamIds) external nonReentrant returns (uint256 totalWithdrawn) {
        uint256 gasStart = gasleft();
        totalWithdrawn = 0;
        
        for (uint256 i = 0; i < streamIds.length; i++) {
            uint256 streamId = streamIds[i];
            
            try streamManager.withdrawAvailable(streamId) returns (uint256 withdrawn) {
                totalWithdrawn += withdrawn;
            } catch {
                // Continue with other streams if one fails
                continue;
            }
        }
        
        uint256 gasUsed = gasStart - gasleft();
        
        emit BatchSettled(msg.sender, streamIds, totalWithdrawn, gasUsed);
    }
    
    function estimateBatchSettlement(uint256[] calldata streamIds) external view returns (
        uint256 estimatedTotal,
        uint256[] memory individualAmounts
    ) {
        individualAmounts = new uint256[](streamIds.length);
        estimatedTotal = 0;
        
        for (uint256 i = 0; i < streamIds.length; i++) {
            uint256 available = streamManager.getAvailableBalance(streamIds[i]);
            individualAmounts[i] = available;
            estimatedTotal += available;
        }
    }
}
