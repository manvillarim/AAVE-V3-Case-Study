import "Structures/GhostPoolStorage.spec";

methods {
    function _.getAddress(bytes32) external => ghostProviderAddress[calledContract] expect address ALL;
    function _.getPoolConfigurator() external => ghostPoolConfigurator[calledContract] expect address ALL;

    function a.ADDRESSES_PROVIDER() external returns (address) envfree;
    function ao.ADDRESSES_PROVIDER() external returns (address) envfree;

    function a.rdConfiguration() external returns (uint256) envfree;
    function ao.rdConfiguration() external returns (uint256) envfree;
    function a.rdLiquidityIndex() external returns (uint128) envfree;
    function ao.rdLiquidityIndex() external returns (uint128) envfree;
    function a.rdCurrentLiquidityRate() external returns (uint128) envfree;
    function ao.rdCurrentLiquidityRate() external returns (uint128) envfree;
    function a.rdVariableBorrowIndex() external returns (uint128) envfree;
    function ao.rdVariableBorrowIndex() external returns (uint128) envfree;
    function a.rdCurrentVariableBorrowRate() external returns (uint128) envfree;
    function ao.rdCurrentVariableBorrowRate() external returns (uint128) envfree;
    function a.rdLastUpdateTimestamp() external returns (uint40) envfree;
    function ao.rdLastUpdateTimestamp() external returns (uint40) envfree;
    function a.rdId() external returns (uint16) envfree;
    function ao.rdId() external returns (uint16) envfree;
    function a.rdATokenAddress() external returns (address) envfree;
    function ao.rdATokenAddress() external returns (address) envfree;
    function a.rdStableDebtTokenAddress() external returns (address) envfree;
    function ao.rdStableDebtTokenAddress() external returns (address) envfree;
    function a.rdVariableDebtTokenAddress() external returns (address) envfree;
    function ao.rdVariableDebtTokenAddress() external returns (address) envfree;
    function a.rdInterestRateStrategyAddress() external returns (address) envfree;
    function ao.rdInterestRateStrategyAddress() external returns (address) envfree;
    function a.rdAccruedToTreasury() external returns (uint128) envfree;
    function ao.rdAccruedToTreasury() external returns (uint128) envfree;
    function a.rdUnbacked() external returns (uint128) envfree;
    function ao.rdUnbacked() external returns (uint128) envfree;
    function a.rdIsolationModeTotalDebt() external returns (uint128) envfree;
    function ao.rdIsolationModeTotalDebt() external returns (uint128) envfree;

    function a.lastConfiguration() external returns (uint256) envfree;
    function ao.lastConfiguration() external returns (uint256) envfree;
    function a.lastUserConfiguration() external returns (uint256) envfree;
    function ao.lastUserConfiguration() external returns (uint256) envfree;
    function a.lastReservesListLength() external returns (uint256) envfree;
    function ao.lastReservesListLength() external returns (uint256) envfree;

    function a.emLtv() external returns (uint16) envfree;
    function ao.emLtv() external returns (uint16) envfree;
    function a.emLiquidationThreshold() external returns (uint16) envfree;
    function ao.emLiquidationThreshold() external returns (uint16) envfree;
    function a.emLiquidationBonus() external returns (uint16) envfree;
    function ao.emLiquidationBonus() external returns (uint16) envfree;
    function a.emPriceSource() external returns (address) envfree;
    function ao.emPriceSource() external returns (address) envfree;
    function a.emLabelHash() external returns (bytes32) envfree;
    function ao.emLabelHash() external returns (bytes32) envfree;
    function a.emLabelLength() external returns (uint256) envfree;
    function ao.emLabelLength() external returns (uint256) envfree;

    function a.ccLtv() external returns (uint16) envfree;
    function ao.ccLtv() external returns (uint16) envfree;
    function a.ccLiquidationThreshold() external returns (uint16) envfree;
    function ao.ccLiquidationThreshold() external returns (uint16) envfree;
    function a.ccLiquidationBonus() external returns (uint16) envfree;
    function ao.ccLiquidationBonus() external returns (uint16) envfree;

    function a.labelHash() external returns (bytes32) envfree;
    function ao.labelHash() external returns (bytes32) envfree;
    function a.labelLength() external returns (uint256) envfree;
    function ao.labelLength() external returns (uint256) envfree;
}

definition couplingInv() returns bool =
    a.ADDRESSES_PROVIDER() == ao.ADDRESSES_PROVIDER() &&
    (forall uint loc. storageOfA[loc] == storageOfAo[loc]);

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

rule gasOptimizedCorrectnessOfGetEModeCategoryData(method f, method g)
filtered {
    f -> f.selector == sig:a.getEModeCategoryData_instr(uint8).selector,
    g -> g.selector == sig:ao.getEModeCategoryData_instr(uint8).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetEModeCategoryLabel(method f, method g)
filtered {
    f -> f.selector == sig:a.getEModeCategoryLabel_instr(uint8).selector,
    g -> g.selector == sig:ao.getEModeCategoryLabel_instr(uint8).selector
} {
    gasOptimizationCorrectness(f, g);
}
