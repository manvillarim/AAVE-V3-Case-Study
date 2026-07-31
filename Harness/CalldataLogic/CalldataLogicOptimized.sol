// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {CalldataLogic} from "aave-v3-origin-optimized/src/contracts/protocol/libraries/logic/CalldataLogic.sol";

contract CalldataLogicOptimized {
    mapping(uint256 => address) internal _reservesList;

    address public lastAsset;
    address public lastAsset2;
    address public lastUser;
    uint256 public lastAmount;
    uint256 public lastInterestRateMode;
    uint256 public lastDeadline;
    uint16 public lastReferralCode;
    uint8 public lastPermitV;
    bool public lastFlag;

    function setReserve(uint256 id, address asset) external {
        _reservesList[id] = asset;
    }

    function decodeSupplyParams_instr(bytes32 args) external {
        (address asset, uint256 amount, uint16 referralCode) = CalldataLogic.decodeSupplyParams(
            _reservesList,
            args
        );
        lastAsset = asset;
        lastAmount = amount;
        lastReferralCode = referralCode;
    }

    function decodeSupplyWithPermitParams_instr(bytes32 args) external {
        (
            address asset,
            uint256 amount,
            uint16 referralCode,
            uint256 deadline,
            uint8 permitV
        ) = CalldataLogic.decodeSupplyWithPermitParams(_reservesList, args);
        lastAsset = asset;
        lastAmount = amount;
        lastReferralCode = referralCode;
        lastDeadline = deadline;
        lastPermitV = permitV;
    }

    function decodeWithdrawParams_instr(bytes32 args) external {
        (address asset, uint256 amount) = CalldataLogic.decodeWithdrawParams(_reservesList, args);
        lastAsset = asset;
        lastAmount = amount;
    }

    function decodeBorrowParams_instr(bytes32 args) external {
        (
            address asset,
            uint256 amount,
            uint256 interestRateMode,
            uint16 referralCode
        ) = CalldataLogic.decodeBorrowParams(_reservesList, args);
        lastAsset = asset;
        lastAmount = amount;
        lastInterestRateMode = interestRateMode;
        lastReferralCode = referralCode;
    }

    function decodeRepayParams_instr(bytes32 args) external {
        (address asset, uint256 amount, uint256 interestRateMode) = CalldataLogic.decodeRepayParams(
            _reservesList,
            args
        );
        lastAsset = asset;
        lastAmount = amount;
        lastInterestRateMode = interestRateMode;
    }

    function decodeRepayWithPermitParams_instr(bytes32 args) external {
        (
            address asset,
            uint256 amount,
            uint256 interestRateMode,
            uint256 deadline,
            uint8 permitV
        ) = CalldataLogic.decodeRepayWithPermitParams(_reservesList, args);
        lastAsset = asset;
        lastAmount = amount;
        lastInterestRateMode = interestRateMode;
        lastDeadline = deadline;
        lastPermitV = permitV;
    }

    function decodeSetUserUseReserveAsCollateralParams_instr(bytes32 args) external {
        (address asset, bool useAsCollateral) = CalldataLogic
            .decodeSetUserUseReserveAsCollateralParams(_reservesList, args);
        lastAsset = asset;
        lastFlag = useAsCollateral;
    }

    function decodeLiquidationCallParams_instr(bytes32 args1, bytes32 args2) external {
        (
            address collateralAsset,
            address debtAsset,
            address user,
            uint256 debtToCover,
            bool receiveAToken
        ) = CalldataLogic.decodeLiquidationCallParams(_reservesList, args1, args2);
        lastAsset = collateralAsset;
        lastAsset2 = debtAsset;
        lastUser = user;
        lastAmount = debtToCover;
        lastFlag = receiveAToken;
    }
}
