// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {CalldataLogic} from "ours/src/contracts/protocol/libraries/logic/CalldataLogic.sol";

contract CalldataLogicOurs {
    mapping(uint256 => address) internal _reservesList;

    function setReserve(uint256 id, address asset) external {
        _reservesList[id] = asset;
    }

    function decodeSupplyParams(bytes32 args) external view returns (address, uint256, uint16) {
        return CalldataLogic.decodeSupplyParams(_reservesList, args);
    }

    function decodeSupplyWithPermitParams(bytes32 args) external view returns (address, uint256, uint16, uint256, uint8) {
        return CalldataLogic.decodeSupplyWithPermitParams(_reservesList, args);
    }

    function decodeWithdrawParams(bytes32 args) external view returns (address, uint256) {
        return CalldataLogic.decodeWithdrawParams(_reservesList, args);
    }

    function decodeBorrowParams(bytes32 args) external view returns (address, uint256, uint256, uint16) {
        return CalldataLogic.decodeBorrowParams(_reservesList, args);
    }

    function decodeRepayParams(bytes32 args) external view returns (address, uint256, uint256) {
        return CalldataLogic.decodeRepayParams(_reservesList, args);
    }

    function decodeRepayWithPermitParams(bytes32 args) external view returns (address, uint256, uint256, uint256, uint8) {
        return CalldataLogic.decodeRepayWithPermitParams(_reservesList, args);
    }

    function decodeSetUserUseReserveAsCollateralParams(bytes32 args) external view returns (address, bool) {
        return CalldataLogic.decodeSetUserUseReserveAsCollateralParams(_reservesList, args);
    }

    function decodeLiquidationCallParams(bytes32 a1, bytes32 a2) external view returns (address, address, address, uint256, bool) {
        return CalldataLogic.decodeLiquidationCallParams(_reservesList, a1, a2);
    }
}
