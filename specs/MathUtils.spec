using MathUtilsOriginal as a;
using MathUtilsOptimized as ao;

methods {
    function a.lastLinearInterest() external returns (uint256) envfree;
    function ao.lastLinearInterest() external returns (uint256) envfree;

    function a.lastCompoundedInterest() external returns (uint256) envfree;
    function ao.lastCompoundedInterest() external returns (uint256) envfree;

    function a.lastCompoundedInterestNow() external returns (uint256) envfree;
    function ao.lastCompoundedInterestNow() external returns (uint256) envfree;
}

definition couplingInv() returns bool =
    a.lastLinearInterest == ao.lastLinearInterest &&
    a.lastCompoundedInterest == ao.lastCompoundedInterest &&
    a.lastCompoundedInterestNow == ao.lastCompoundedInterestNow;

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

rule gasOptimizedCorrectnessOfCalculateLinearInterest(method f, method g)
filtered {
    f -> f.selector == sig:a.calculateLinearInterest_instr(uint256, uint40).selector,
    g -> g.selector == sig:ao.calculateLinearInterest_instr(uint256, uint40).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCalculateCompoundedInterest(method f, method g)
filtered {
    f -> f.selector == sig:a.calculateCompoundedInterest_instr(uint256, uint40, uint256).selector,
    g -> g.selector == sig:ao.calculateCompoundedInterest_instr(uint256, uint40, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCalculateCompoundedInterestNow(method f, method g)
filtered {
    f -> f.selector == sig:a.calculateCompoundedInterestNow_instr(uint256, uint40).selector,
    g -> g.selector == sig:ao.calculateCompoundedInterestNow_instr(uint256, uint40).selector
} {
    gasOptimizationCorrectness(f, g);
}
