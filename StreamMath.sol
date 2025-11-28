// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library StreamMath {
    error InvalidStreamParameters();
    error InsufficientDeposit();
    
    function calculateOwedAmount(
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp,
        uint256 ratePerSecond,
        uint256 balance
    ) internal pure returns (uint256 owed, uint256 newBalance, bool isDepleted) {
        if (lastUpdateTimestamp >= currentTimestamp) {
            return (0, balance, false);
        }
        
        uint256 timeElapsed = currentTimestamp - lastUpdateTimestamp;
        uint256 totalOwed = timeElapsed * ratePerSecond;
        
        if (totalOwed >= balance) {
            owed = balance;
            newBalance = 0;
            isDepleted = true;
        } else {
            owed = totalOwed;
            newBalance = balance - totalOwed;
            isDepleted = false;
        }
    }
    
    function validateStreamParameters(
        address payer,
        address payee,
        uint256 ratePerSecond,
        uint256 depositAmount
    ) internal pure {
        if (payer == address(0) || payee == address(0) || payee == payer) {
            revert InvalidStreamParameters();
        }
        if (ratePerSecond == 0 || depositAmount == 0) {
            revert InvalidStreamParameters();
        }
        if (depositAmount < ratePerSecond * 3600) { // Minimum 1 hour of streaming
            revert InsufficientDeposit();
        }
    }
}
