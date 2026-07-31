import "Structures/GhostPool.spec";

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
    a._reservesCount == ao._reservesCount &&
    a._bridgeProtocolFee == ao._bridgeProtocolFee &&
    a._flashLoanPremiumTotal == ao._flashLoanPremiumTotal &&
    a._flashLoanPremiumToProtocol == ao._flashLoanPremiumToProtocol &&
    (forall address asset. ghost_a_r_cfg[asset] == ghost_ao_r_cfg[asset]) &&
    (forall address asset. ghost_a_r_li[asset] == ghost_ao_r_li[asset]) &&
    (forall address asset. ghost_a_r_clr[asset] == ghost_ao_r_clr[asset]) &&
    (forall address asset. ghost_a_r_vbi[asset] == ghost_ao_r_vbi[asset]) &&
    (forall address asset. ghost_a_r_cvbr[asset] == ghost_ao_r_cvbr[asset]) &&
    (forall address asset. ghost_a_r_def[asset] == ghost_ao_r_def[asset]) &&
    (forall address asset. ghost_a_r_lut[asset] == ghost_ao_r_lut[asset]) &&
    (forall address asset. ghost_a_r_id[asset] == ghost_ao_r_id[asset]) &&
    (forall address asset. ghost_a_r_lgp[asset] == ghost_ao_r_lgp[asset]) &&
    (forall address asset. ghost_a_r_at[asset] == ghost_ao_r_at[asset]) &&
    (forall address asset. ghost_a_r_vdt[asset] == ghost_ao_r_vdt[asset]) &&
    (forall address asset. ghost_a_r_irs[asset] == ghost_ao_r_irs[asset]) &&
    (forall address asset. ghost_a_r_att[asset] == ghost_ao_r_att[asset]) &&
    (forall address asset. ghost_a_r_unb[asset] == ghost_ao_r_unb[asset]) &&
    (forall address asset. ghost_a_r_imtd[asset] == ghost_ao_r_imtd[asset]) &&
    (forall address asset. ghost_a_r_vub[asset] == ghost_ao_r_vub[asset]) &&
    (forall uint8 id. ghost_a_e_ltv[id] == ghost_ao_e_ltv[id]) &&
    (forall uint8 id. ghost_a_e_lt[id] == ghost_ao_e_lt[id]) &&
    (forall uint8 id. ghost_a_e_lb[id] == ghost_ao_e_lb[id]) &&
    (forall uint8 id. ghost_a_e_cbm[id] == ghost_ao_e_cbm[id]) &&
    (forall uint8 id. ghost_a_e_bbm[id] == ghost_ao_e_bbm[id]) &&
    (forall uint8 id. ghost_a_e_label[id] == ghost_ao_e_label[id]) &&
    (forall address user. ghost_a_uc[user] == ghost_ao_uc[user]) &&
    (forall address user. ghost_a_uem[user] == ghost_ao_uem[user]) &&
    (forall uint256 i. ghost_a_rl[i] == ghost_ao_rl[i]) &&
    (forall uint256 i. ghost_a_lrl[i] == ghost_ao_lrl[i]) &&
    a.rdConfiguration == ao.rdConfiguration &&
    a.rdLiquidityIndex == ao.rdLiquidityIndex &&
    a.rdCurrentLiquidityRate == ao.rdCurrentLiquidityRate &&
    a.rdVariableBorrowIndex == ao.rdVariableBorrowIndex &&
    a.rdCurrentVariableBorrowRate == ao.rdCurrentVariableBorrowRate &&
    a.rdLastUpdateTimestamp == ao.rdLastUpdateTimestamp &&
    a.rdId == ao.rdId &&
    a.rdATokenAddress == ao.rdATokenAddress &&
    a.rdStableDebtTokenAddress == ao.rdStableDebtTokenAddress &&
    a.rdVariableDebtTokenAddress == ao.rdVariableDebtTokenAddress &&
    a.rdInterestRateStrategyAddress == ao.rdInterestRateStrategyAddress &&
    a.rdAccruedToTreasury == ao.rdAccruedToTreasury &&
    a.rdUnbacked == ao.rdUnbacked &&
    a.rdIsolationModeTotalDebt == ao.rdIsolationModeTotalDebt &&
    a.lastConfiguration == ao.lastConfiguration &&
    a.lastUserConfiguration == ao.lastUserConfiguration &&
    a.lastReservesListLength == ao.lastReservesListLength &&
    a.emLtv == ao.emLtv &&
    a.emLiquidationThreshold == ao.emLiquidationThreshold &&
    a.emLiquidationBonus == ao.emLiquidationBonus &&
    a.emPriceSource == ao.emPriceSource &&
    a.emLabelHash == ao.emLabelHash &&
    a.emLabelLength == ao.emLabelLength &&
    a.ccLtv == ao.ccLtv &&
    a.ccLiquidationThreshold == ao.ccLiquidationThreshold &&
    a.ccLiquidationBonus == ao.ccLiquidationBonus &&
    a.labelHash == ao.labelHash &&
    a.labelLength == ao.labelLength;

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

rule gasOptimizedCorrectnessOfGetReserveData(method f, method g)
filtered {
    f -> f.selector == sig:a.getReserveData_instr(address).selector,
    g -> g.selector == sig:ao.getReserveData_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetConfiguration(method f, method g)
filtered {
    f -> f.selector == sig:a.getConfiguration_instr(address).selector,
    g -> g.selector == sig:ao.getConfiguration_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetUserConfiguration(method f, method g)
filtered {
    f -> f.selector == sig:a.getUserConfiguration_instr(address).selector,
    g -> g.selector == sig:ao.getUserConfiguration_instr(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetReservesList(method f, method g)
filtered {
    f -> f.selector == sig:a.getReservesList_instr().selector,
    g -> g.selector == sig:ao.getReservesList_instr().selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetEModeCategoryData(method f, method g)
filtered {
    f -> f.selector == sig:a.getEModeCategoryData_instr(uint8).selector,
    g -> g.selector == sig:ao.getEModeCategoryData_instr(uint8).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetEModeCategoryCollateralConfig(method f, method g)
filtered {
    f -> f.selector == sig:a.getEModeCategoryCollateralConfig_instr(uint8).selector,
    g -> g.selector == sig:ao.getEModeCategoryCollateralConfig_instr(uint8).selector
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

rule gasOptimizedCorrectnessOfSetReserveInterestRateStrategyAddress(method f, method g)
filtered {
    f -> f.selector == sig:a.setReserveInterestRateStrategyAddress(address, address).selector,
    g -> g.selector == sig:ao.setReserveInterestRateStrategyAddress(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetConfiguration(method f, method g)
filtered {
    f -> f.selector == sig:a.setConfiguration(address, DataTypesOrig.ReserveConfigurationMap).selector,
    g -> g.selector == sig:ao.setConfiguration(address, DataTypes.ReserveConfigurationMap).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfUpdateBridgeProtocolFee(method f, method g)
filtered {
    f -> f.selector == sig:a.updateBridgeProtocolFee(uint256).selector,
    g -> g.selector == sig:ao.updateBridgeProtocolFee(uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfUpdateFlashloanPremiums(method f, method g)
filtered {
    f -> f.selector == sig:a.updateFlashloanPremiums(uint128, uint128).selector,
    g -> g.selector == sig:ao.updateFlashloanPremiums(uint128, uint128).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfConfigureEModeCategory(method f, method g)
filtered {
    f -> f.selector == sig:a.configureEModeCategory(uint8, DataTypesOrig.EModeCategoryBaseConfiguration).selector,
    g -> g.selector == sig:ao.configureEModeCategory(uint8, DataTypes.EModeCategoryBaseConfiguration).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfConfigureEModeCategoryCollateralBitmap(method f, method g)
filtered {
    f -> f.selector == sig:a.configureEModeCategoryCollateralBitmap(uint8, uint128).selector,
    g -> g.selector == sig:ao.configureEModeCategoryCollateralBitmap(uint8, uint128).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfConfigureEModeCategoryBorrowableBitmap(method f, method g)
filtered {
    f -> f.selector == sig:a.configureEModeCategoryBorrowableBitmap(uint8, uint128).selector,
    g -> g.selector == sig:ao.configureEModeCategoryBorrowableBitmap(uint8, uint128).selector
} {
    gasOptimizationCorrectness(f, g);
}













