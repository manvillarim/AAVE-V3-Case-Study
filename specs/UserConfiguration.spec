using UserConfigurationOriginal as a;
using UserConfigurationOptimized as ao;

methods {
    function a.lastBoolReturn() external returns (bool) envfree;
    function ao.lastBoolReturn() external returns (bool) envfree;

    function a.lastUintReturn() external returns (uint256) envfree;
    function ao.lastUintReturn() external returns (uint256) envfree;
}

definition couplingInv() returns bool =
    (forall address user.
        a._usersConfig[user].data == ao._usersConfig[user].data
    ) &&
    a.lastBoolReturn == ao.lastBoolReturn &&
    a.lastUintReturn == ao.lastUintReturn;

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

rule gasOptimizedCorrectnessOfSetBorrowing(method f, method g)
filtered {
    f -> f.selector == sig:a.setBorrowing_instr(address, uint256, bool).selector,
    g -> g.selector == sig:ao.setBorrowing_instr(address, uint256, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetBorrowingCached(method f, method g)
filtered {
    f -> f.selector == sig:a.setBorrowingCached_instr(address, uint256, bool).selector,
    g -> g.selector == sig:ao.setBorrowingCached_instr(address, uint256, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetUsingAsCollateral(method f, method g)
filtered {
    f -> f.selector == sig:a.setUsingAsCollateral_instr(address, uint256, bool).selector,
    g -> g.selector == sig:ao.setUsingAsCollateral_instr(address, uint256, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetUsingAsCollateralCached(method f, method g)
filtered {
    f -> f.selector == sig:a.setUsingAsCollateralCached_instr(address, uint256, bool).selector,
    g -> g.selector == sig:ao.setUsingAsCollateralCached_instr(address, uint256, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsUsingAsCollateralOrBorrowing(method f, method g)
filtered {
    f -> f.selector == sig:a.isUsingAsCollateralOrBorrowing_instr(address, uint256).selector,
    g -> g.selector == sig:ao.isUsingAsCollateralOrBorrowing_instr(address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsBorrowing(method f, method g)
filtered {
    f -> f.selector == sig:a.isBorrowing_instr(address, uint256).selector,
    g -> g.selector == sig:ao.isBorrowing_instr(address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsUsingAsCollateral(method f, method g)
filtered {
    f -> f.selector == sig:a.isUsingAsCollateral_instr(address, uint256).selector,
    g -> g.selector == sig:ao.isUsingAsCollateral_instr(address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsUsingAsCollateralOne(method f, method g)
filtered {
    f -> f.selector == sig:a.isUsingAsCollateralOne_instr(address).selector,
    g -> g.selector == sig:ao.isUsingAsCollateralOne_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsUsingAsCollateralAny(method f, method g)
filtered {
    f -> f.selector == sig:a.isUsingAsCollateralAny_instr(address).selector,
    g -> g.selector == sig:ao.isUsingAsCollateralAny_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsBorrowingOne(method f, method g)
filtered {
    f -> f.selector == sig:a.isBorrowingOne_instr(address).selector,
    g -> g.selector == sig:ao.isBorrowingOne_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsBorrowingAny(method f, method g)
filtered {
    f -> f.selector == sig:a.isBorrowingAny_instr(address).selector,
    g -> g.selector == sig:ao.isBorrowingAny_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsEmpty(method f, method g)
filtered {
    f -> f.selector == sig:a.isEmpty_instr(address).selector,
    g -> g.selector == sig:ao.isEmpty_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetFirstAssetIdByMask(method f, method g)
filtered {
    f -> f.selector == sig:a.getFirstAssetIdByMask_instr(address, uint256).selector,
    g -> g.selector == sig:ao.getFirstAssetIdByMask_instr(address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}
