// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StreamManager.sol";

contract UsageOracle is AccessControl, ReentrancyGuard {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    StreamManager public streamManager;
    
    event UsageRateSet(uint256 indexed streamId, uint256 ratePerUnit);
    event UsageRecorded(uint256 indexed streamId, uint256 units, uint256 totalFees);
    
    mapping(uint256 => uint256) public usageRates; // streamId -> ratePerUnit
    
    constructor(address streamManagerAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        streamManager = StreamManager(streamManagerAddress);
    }
    
    function recordUsage(uint256 streamId, uint256 units) external onlyRole(ORACLE_ROLE) {
        uint256 ratePerUnit = usageRates[streamId];
        require(ratePerUnit > 0, "Usage rate not set");
        
        uint256 fees = units * ratePerUnit;
        
        // In a real implementation, this would track usage fees separately
        // For simplicity, we emit events that can be indexed off-chain
        
        emit UsageRecorded(streamId, units, fees);
    }
    
    function setRateForUsage(uint256 streamId, uint256 ratePerUnit) external {
        // Only stream participants can set usage rates
        IPaymentStream.Stream memory stream = streamManager.getStream(streamId);
        require(
            msg.sender == stream.payer || msg.sender == stream.payee,
            "Not stream participant"
        );
        
        usageRates[streamId] = ratePerUnit;
        
        emit UsageRateSet(streamId, ratePerUnit);
    }
    
    function withdrawUsageFees(uint256 streamId) external nonReentrant {
        // Implementation would track and distribute usage-based fees
        // This is a simplified version
        revert("Usage fee withdrawal not implemented in this version");
    }
    
    function addOracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ORACLE_ROLE, oracle);
    }
    
    function removeOracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ORACLE_ROLE, oracle);
    }
}
