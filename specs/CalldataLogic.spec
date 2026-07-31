using CalldataLogicOriginal as a;
using CalldataLogicOptimized as ao;

methods {
    function a.lastAsset() external returns (address) envfree;
    function ao.lastAsset() external returns (address) envfree;

    function a.lastAsset2() external returns (address) envfree;
    function ao.lastAsset2() external returns (address) envfree;

    function a.lastUser() external returns (address) envfree;
    function ao.lastUser() external returns (address) envfree;

    function a.lastAmount() external returns (uint256) envfree;
    function ao.lastAmount() external returns (uint256) envfree;

    function a.lastInterestRateMode() external returns (uint256) envfree;
    function ao.lastInterestRateMode() external returns (uint256) envfree;

    function a.lastDeadline() external returns (uint256) envfree;
    function ao.lastDeadline() external returns (uint256) envfree;

    function a.lastReferralCode() external returns (uint16) envfree;
    function ao.lastReferralCode() external returns (uint16) envfree;

    function a.lastPermitV() external returns (uint8) envfree;
    function ao.lastPermitV() external returns (uint8) envfree;

    function a.lastFlag() external returns (bool) envfree;
    function ao.lastFlag() external returns (bool) envfree;
}

definition couplingInv() returns bool =
    (forall uint256 id.
        a._reservesList[id] == ao._reservesList[id]
    ) &&
    a.lastAsset == ao.lastAsset &&
    a.lastAsset2 == ao.lastAsset2 &&
    a.lastUser == ao.lastUser &&
    a.lastAmount == ao.lastAmount &&
    a.lastInterestRateMode == ao.lastInterestRateMode &&
    a.lastDeadline == ao.lastDeadline &&
    a.lastReferralCode == ao.lastReferralCode &&
    a.lastPermitV == ao.lastPermitV &&
    a.lastFlag == ao.lastFlag;

function gasOptimizationCorrectness(method f, method g) {
    env eA;
    env eAo;
    calldataarg args;

    require eA == eAo && couplingInv();

    a.f@withrevert(eA, args);
    bool a_reverted = lastReverted;

    ao.g@withrevert(eAo, args);
    bool ao_reverted = lastReverted;

    assert a_reverted == ao_reverted;
    assert couplingInv();
}

rule gasOptimizedCorrectnessOfDecodeSupplyParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeSupplyParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeSupplyParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeSupplyWithPermitParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeSupplyWithPermitParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeSupplyWithPermitParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeWithdrawParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeWithdrawParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeWithdrawParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeBorrowParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeBorrowParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeBorrowParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeRepayParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeRepayParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeRepayParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeRepayWithPermitParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeRepayWithPermitParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeRepayWithPermitParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeSetUserUseReserveAsCollateralParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeSetUserUseReserveAsCollateralParams_instr(bytes32).selector,
    g -> g.selector == sig:ao.decodeSetUserUseReserveAsCollateralParams_instr(bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDecodeLiquidationCallParams(method f, method g)
filtered {
    f -> f.selector == sig:a.decodeLiquidationCallParams_instr(bytes32, bytes32).selector,
    g -> g.selector == sig:ao.decodeLiquidationCallParams_instr(bytes32, bytes32).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetReserve(method f, method g)
filtered {
    f -> f.selector == sig:a.setReserve(uint256, address).selector,
    g -> g.selector == sig:ao.setReserve(uint256, address).selector
} {
    gasOptimizationCorrectness(f, g);
}
