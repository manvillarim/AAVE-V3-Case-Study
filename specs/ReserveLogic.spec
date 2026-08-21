import "Structures/GhostReserveLogic.spec";

methods {
    function _.scaledTotalSupply() external => ghostScaledTotalSupply[calledContract] expect uint256 ALL;
    function _.calculateInterestRates(DataTypes.CalculateInterestRatesParams) external
        => interestRatesSummary(calledContract) expect (uint256, uint256) ALL;

    function _.calculateLinearInterest(uint256 rate, uint40 t) internal
        => linearInterestSummary(rate, t) expect uint256 ALL;
    function _.calculateCompoundedInterest(uint256 rate, uint40 t0, uint256 t1) internal
        => compoundedInterestSummary(rate, t0, t1) expect uint256 ALL;

    function a.lastNormalizedIncome() external returns (uint256) envfree;
    function ao.lastNormalizedIncome() external returns (uint256) envfree;
    function a.lastNormalizedDebt() external returns (uint256) envfree;
    function ao.lastNormalizedDebt() external returns (uint256) envfree;
    function a.lastCumulateIndex() external returns (uint256) envfree;
    function ao.lastCumulateIndex() external returns (uint256) envfree;

    function a.cCurrScaledVariableDebt() external returns (uint256) envfree;
    function ao.cCurrScaledVariableDebt() external returns (uint256) envfree;
    function a.cNextScaledVariableDebt() external returns (uint256) envfree;
    function ao.cNextScaledVariableDebt() external returns (uint256) envfree;
    function a.cCurrLiquidityIndex() external returns (uint256) envfree;
    function ao.cCurrLiquidityIndex() external returns (uint256) envfree;
    function a.cNextLiquidityIndex() external returns (uint256) envfree;
    function ao.cNextLiquidityIndex() external returns (uint256) envfree;
    function a.cCurrVariableBorrowIndex() external returns (uint256) envfree;
    function ao.cCurrVariableBorrowIndex() external returns (uint256) envfree;
    function a.cNextVariableBorrowIndex() external returns (uint256) envfree;
    function ao.cNextVariableBorrowIndex() external returns (uint256) envfree;
    function a.cCurrLiquidityRate() external returns (uint256) envfree;
    function ao.cCurrLiquidityRate() external returns (uint256) envfree;
    function a.cCurrVariableBorrowRate() external returns (uint256) envfree;
    function ao.cCurrVariableBorrowRate() external returns (uint256) envfree;
    function a.cReserveFactor() external returns (uint256) envfree;
    function ao.cReserveFactor() external returns (uint256) envfree;
    function a.cReserveConfiguration() external returns (uint256) envfree;
    function ao.cReserveConfiguration() external returns (uint256) envfree;
    function a.cATokenAddress() external returns (address) envfree;
    function ao.cATokenAddress() external returns (address) envfree;
    function a.cVariableDebtTokenAddress() external returns (address) envfree;
    function ao.cVariableDebtTokenAddress() external returns (address) envfree;
    function a.cReserveLastUpdateTimestamp() external returns (uint40) envfree;
    function ao.cReserveLastUpdateTimestamp() external returns (uint40) envfree;
}

definition couplingInv() returns bool =
    (forall address asset. ghost_a_cfg[asset] == ghost_ao_cfg[asset]) &&
    (forall address asset. ghost_a_li[asset] == ghost_ao_li[asset]) &&
    (forall address asset. ghost_a_clr[asset] == ghost_ao_clr[asset]) &&
    (forall address asset. ghost_a_vbi[asset] == ghost_ao_vbi[asset]) &&
    (forall address asset. ghost_a_cvbr[asset] == ghost_ao_cvbr[asset]) &&
    (forall address asset. ghost_a_lut[asset] == ghost_ao_lut[asset]) &&
    (forall address asset. ghost_a_id[asset] == ghost_ao_id[asset]) &&
    (forall address asset. ghost_a_at[asset] == ghost_ao_at[asset]) &&
    (forall address asset. ghost_a_vdt[asset] == ghost_ao_vdt[asset]) &&
    (forall address asset. ghost_a_irs[asset] == ghost_ao_irs[asset]) &&
    (forall address asset. ghost_a_att[asset] == ghost_ao_att[asset]) &&
    (forall address asset. ghost_a_vub[asset] == ghost_ao_vub[asset]) &&
    a.lastNormalizedIncome == ao.lastNormalizedIncome &&
    a.lastNormalizedDebt == ao.lastNormalizedDebt &&
    a.lastCumulateIndex == ao.lastCumulateIndex &&
    a.cCurrScaledVariableDebt == ao.cCurrScaledVariableDebt &&
    a.cNextScaledVariableDebt == ao.cNextScaledVariableDebt &&
    a.cCurrLiquidityIndex == ao.cCurrLiquidityIndex &&
    a.cNextLiquidityIndex == ao.cNextLiquidityIndex &&
    a.cCurrVariableBorrowIndex == ao.cCurrVariableBorrowIndex &&
    a.cNextVariableBorrowIndex == ao.cNextVariableBorrowIndex &&
    a.cCurrLiquidityRate == ao.cCurrLiquidityRate &&
    a.cCurrVariableBorrowRate == ao.cCurrVariableBorrowRate &&
    a.cReserveFactor == ao.cReserveFactor &&
    a.cReserveConfiguration == ao.cReserveConfiguration &&
    a.cATokenAddress == ao.cATokenAddress &&
    a.cVariableDebtTokenAddress == ao.cVariableDebtTokenAddress &&
    a.cReserveLastUpdateTimestamp == ao.cReserveLastUpdateTimestamp;

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

rule gasOptimizedCorrectnessOfGetNormalizedIncome(method f, method g)
filtered {
    f -> f.selector == sig:a.getNormalizedIncome_instr(address).selector,
    g -> g.selector == sig:ao.getNormalizedIncome_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetNormalizedDebt(method f, method g)
filtered {
    f -> f.selector == sig:a.getNormalizedDebt_instr(address).selector,
    g -> g.selector == sig:ao.getNormalizedDebt_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCumulateToLiquidityIndex(method f, method g)
filtered {
    f -> f.selector == sig:a.cumulateToLiquidityIndex_instr(address, uint256, uint256).selector,
    g -> g.selector == sig:ao.cumulateToLiquidityIndex_instr(address, uint256, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCache(method f, method g)
filtered {
    f -> f.selector == sig:a.cache_instr(address).selector,
    g -> g.selector == sig:ao.cache_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfUpdateState(method f, method g)
filtered {
    f -> f.selector == sig:a.updateState_instr(address).selector,
    g -> g.selector == sig:ao.updateState_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfInit(method f, method g)
filtered {
    f -> f.selector == sig:a.init_instr(address, address, address, address).selector,
    g -> g.selector == sig:ao.init_instr(address, address, address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}
