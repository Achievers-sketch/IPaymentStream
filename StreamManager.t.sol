// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/StreamManager.sol";
import "../contracts/UsageOracle.sol";
import "../contracts/BatchSettler.sol";

contract StreamManagerTest is Test {
    StreamManager public streamManager;
    UsageOracle public usageOracle;
    BatchSettler public batchSettler;
    
    address payable public payer = payable(address(0x1));
    address payable public payee = payable(address(0x2));
    address public oracle = address(0x3);
    
    uint256 constant RATE_PER_SECOND = 1 ether / 86400; // 1 ETH per day
    uint256 constant DEPOSIT_AMOUNT = 1 ether;
    
    function setUp() public {
        vm.deal(payer, 10 ether);
        vm.deal(payee, 10 ether);
        
        streamManager = new StreamManager();
        usageOracle = new UsageOracle(address(streamManager));
        batchSettler = new BatchSettler(address(streamManager));
        
        streamManager.grantRole(streamManager.ORACLE_ROLE(), address(usageOracle));
    }
    
    function testOpenStream() public {
        vm.prank(payer);
        uint256 streamId = streamManager.openStream{value: DEPOSIT_AMOUNT}(
            payee,
            RATE_PER_SECOND,
            DEPOSIT_AMOUNT
        );
        
        assertEq(streamId, 0);
        assertEq(address(streamManager).balance, DEPOSIT_AMOUNT);
        
        IPaymentStream.Stream memory stream = streamManager.getStream(streamId);
        assertEq(stream.payer, payer);
        assertEq(stream.payee, payee);
        assertEq(stream.ratePerSecond, RATE_PER_SECOND);
        assertTrue(stream.isActive);
    }
    
    function testWithdrawAvailable() public {
        vm.prank(payer);
        uint256 streamId = streamManager.openStream{value: DEPOSIT_AMOUNT}(
            payee,
            RATE_PER_SECOND,
            DEPOSIT_AMOUNT
        );
        
        // Fast forward 1 day
        vm.warp(block.timestamp + 86400);
        
        vm.prank(payee);
        uint256 withdrawn = streamManager.withdrawAvailable(streamId);
        
        assertEq(withdrawn, DEPOSIT_AMOUNT);
        assertEq(payee.balance, 10 ether + DEPOSIT_AMOUNT);
    }
    
    function testUpdateRate() public {
        vm.prank(payer);
        uint256 streamId = streamManager.openStream{value: DEPOSIT_AMOUNT}(
            payee,
            RATE_PER_SECOND,
            DEPOSIT_AMOUNT
        );
        
        uint256 newRate = RATE_PER_SECOND * 2;
        vm.prank(payer);
        streamManager.updateRate(streamId, newRate);
        
        IPaymentStream.Stream memory stream = streamManager.getStream(streamId);
        assertEq(stream.ratePerSecond, newRate);
    }
    
    function testBatchSettlement() public {
        // Create multiple streams
        uint256[] memory streamIds = new uint256[](3);
        
        for (uint256 i = 0; i < 3; i++) {
            address newPayee = address(uint160(payee) + i + 1);
            vm.deal(payer, 10 ether);
            
            vm.prank(payer);
            streamIds[i] = streamManager.openStream{value: DEPOSIT_AMOUNT}(
                newPayee,
                RATE_PER_SECOND,
                DEPOSIT_AMOUNT
            );
        }
        
        // Fast forward
        vm.warp(block.timestamp + 86400);
        
        // Batch settle
        uint256 gasBefore = gasleft();
        uint256 totalWithdrawn = batchSettler.batchSettle(streamIds);
        uint256 gasUsed = gasBefore - gasleft();
        
        assertTrue(totalWithdrawn > 0);
        assertTrue(gasUsed > 0);
    }
    
    function testUsageRecording() public {
        vm.prank(payer);
        uint256 streamId = streamManager.openStream{value: DEPOSIT_AMOUNT}(
            payee,
            RATE_PER_SECOND,
            DEPOSIT_AMOUNT
        );
        
        // Set usage rate
        vm.prank(payer);
        usageOracle.setRateForUsage(streamId, 0.001 ether);
        
        // Record usage as oracle
        vm.prank(address(usageOracle));
        usageOracle.recordUsage(streamId, 100);
        
        // Verify events
        vm.expectEmit(true, true, true, true);
        emit UsageRecorded(streamId, 100, 0.1 ether);
    }
}
