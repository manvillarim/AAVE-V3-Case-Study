// SPDX-License-Identifier:  BUSL-1.1
pragma solidity ^0.8.10;

import {Collector} from "aave-v3-origin-optimized-instr/src/contracts/treasury/Collector.sol";

contract CollectorOptimized is Collector {
    uint256 public lastDeltaOfReturn;
    uint256 public lastBalanceOfReturn;

    uint256 public lastCreateStreamId;
    address public lastCreateSender;
    address public lastCreateRecipient;
    uint256 public lastCreateDeposit;
    address public lastCreateTokenAddress;
    uint256 public lastCreateStartTime;
    uint256 public lastCreateStopTime;

    uint256 public emitCount;
    bytes32 public emitDigest;

    uint256 public lastWithdrawStreamId;
    address public lastWithdrawRecipient;
    uint256 public lastWithdrawAmount;

    uint256 public lastCancelStreamId;
    address public lastCancelSender;
    address public lastCancelRecipient;
    uint256 public lastCancelSenderBalance;
    uint256 public lastCancelRecipientBalance;

    function deltaOf_instr(uint256 streamId) external returns (uint256) {
        uint256 r = deltaOf(streamId);
        lastDeltaOfReturn = r;
        return r;
    }

    function balanceOf_instr(uint256 streamId, address who) external returns (uint256) {
        uint256 r = balanceOf(streamId, who);
        lastBalanceOfReturn = r;
        return r;
    }

    function _recordCreateStream(
        uint256 streamId,
        address sender,
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) internal override {
        lastCreateStreamId = streamId;
        lastCreateSender = sender;
        lastCreateRecipient = recipient;
        lastCreateDeposit = deposit;
        lastCreateTokenAddress = tokenAddress;
        lastCreateStartTime = startTime;
        lastCreateStopTime = stopTime;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "CreateStream",
                streamId,
                sender,
                recipient,
                deposit,
                tokenAddress,
                startTime,
                stopTime
            )
        );
    }

    function _recordWithdrawFromStream(
        uint256 streamId,
        address recipient,
        uint256 amount
    ) internal override {
        lastWithdrawStreamId = streamId;
        lastWithdrawRecipient = recipient;
        lastWithdrawAmount = amount;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "WithdrawFromStream", streamId, recipient, amount)
        );
    }

    function _recordCancelStream(
        uint256 streamId,
        address sender,
        address recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    ) internal override {
        lastCancelStreamId = streamId;
        lastCancelSender = sender;
        lastCancelRecipient = recipient;
        lastCancelSenderBalance = senderBalance;
        lastCancelRecipientBalance = recipientBalance;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "CancelStream",
                streamId,
                sender,
                recipient,
                senderBalance,
                recipientBalance
            )
        );
    }
}
