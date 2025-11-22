using PoolOriginal as a;
using PoolOptimized as ao;

methods {
    function a.supply(address, uint256, address, uint16) external;
    function ao.supply(address, uint256, address, uint16) external;
    
    function a.withdraw(address, uint256, address) external returns (uint256);
    function ao.withdraw(address, uint256, address) external returns (uint256);
    
    function a.setUserUseReserveAsCollateral(address, bool) external;
    function ao.setUserUseReserveAsCollateral(address, bool) external;
    
    function a.borrow(address, uint256, uint256, uint16, address) external;
    function ao.borrow(address, uint256, uint256, uint16, address) external;
    
    function a.repay(address, uint256, uint256, address) external returns (uint256);
    function ao.repay(address, uint256, uint256, address) external returns (uint256);
    
    function a.repayWithATokens(address, uint256, uint256) external returns (uint256);
    function ao.repayWithATokens(address, uint256, uint256) external returns (uint256);

    function a.liquidationCall(address, address, address, uint256, bool) external;
    function ao.liquidationCall(address, address, address, uint256, bool) external;
    
    function a.flashLoan(address, address[], uint256[], uint256[], address, bytes, uint16) external;
    function ao.flashLoan(address, address[], uint256[], uint256[], address, bytes, uint16) external;
    
    function a.flashLoanSimple(address, address, uint256, bytes, uint16) external;
    function ao.flashLoanSimple(address, address, uint256, bytes, uint16) external;
    
    function a.getReserveNormalizedIncome(address) external returns (uint256) envfree;
    function ao.getReserveNormalizedIncome(address) external returns (uint256) envfree;
    
    function a.getReserveNormalizedVariableDebt(address) external returns (uint256) envfree;
    function ao.getReserveNormalizedVariableDebt(address) external returns (uint256) envfree;
    
    function a.getReservesList() external returns (address[]) envfree;
    function ao.getReservesList() external returns (address[]) envfree;
    
    function a.getReservesCount() external returns (uint256) envfree;
    function ao.getReservesCount() external returns (uint256) envfree;
    
    function a.getUserEMode(address) external returns (uint256) envfree;
    function ao.getUserEMode(address) external returns (uint256) envfree;
    
    function a.getEModeCategoryLabel(uint8) external returns (string) envfree;
    function ao.getEModeCategoryLabel(uint8) external returns (string) envfree;
    
    function a.BRIDGE_PROTOCOL_FEE() external returns (uint256) envfree;
    function ao.BRIDGE_PROTOCOL_FEE() external returns (uint256) envfree;
    
    function a.FLASHLOAN_PREMIUM_TOTAL() external returns (uint128) envfree;
    function ao.FLASHLOAN_PREMIUM_TOTAL() external returns (uint128) envfree;
    
    function a.FLASHLOAN_PREMIUM_TO_PROTOCOL() external returns (uint128) envfree;
    function ao.FLASHLOAN_PREMIUM_TO_PROTOCOL() external returns (uint128) envfree;
    
    function a.MAX_NUMBER_RESERVES() external returns (uint16) envfree;
    function ao.MAX_NUMBER_RESERVES() external returns (uint16) envfree;
    
    function a.initReserve(address, address, address, address) external;
    function ao.initReserve(address, address, address, address) external;
    
    function a.dropReserve(address) external;
    function ao.dropReserve(address) external;
    
    function a.setReserveInterestRateStrategyAddress(address, address) external;
    function ao.setReserveInterestRateStrategyAddress(address, address) external;
    
    function a.setConfiguration(address, DataTypes.ReserveConfigurationMap) external;
    function ao.setConfiguration(address, DataTypes.ReserveConfigurationMap) external;
    
    function a.updateBridgeProtocolFee(uint256) external;
    function ao.updateBridgeProtocolFee(uint256) external;
    
    function a.updateFlashloanPremiums(uint128, uint128) external;
    function ao.updateFlashloanPremiums(uint128, uint128) external;
    
    function a.setUserEMode(uint8) external;
    function ao.setUserEMode(uint8) external;
    
    function a.configureEModeCategory(uint8, DataTypes.EModeCategoryBaseConfiguration) external;
    function ao.configureEModeCategory(uint8, DataTypes.EModeCategoryBaseConfiguration) external;
    
    function a.resetIsolationModeTotalDebt(address) external;
    function ao.resetIsolationModeTotalDebt(address) external;
    
    function a.setLiquidationGracePeriod(address, uint40) external;
    function ao.setLiquidationGracePeriod(address, uint40) external;
    
    function a.rescueTokens(address, address, uint256) external;
    function ao.rescueTokens(address, address, uint256) external;
}

definition couplingInv() returns bool =
    // Contadores de reserves devem ser iguais
    a._reservesCount == ao._reservesCount &&
    
    // Para cada reserve, os dados críticos devem ser iguais
    (forall address asset.
        // Configuration
        a._reserves[asset].configuration.data == ao._reserves[asset].configuration.data &&
        
        // Indexes
        a._reserves[asset].liquidityIndex == ao._reserves[asset].liquidityIndex &&
        a._reserves[asset].variableBorrowIndex == ao._reserves[asset].variableBorrowIndex &&
        
        // Rates
        a._reserves[asset].currentLiquidityRate == ao._reserves[asset].currentLiquidityRate &&
        a._reserves[asset].currentVariableBorrowRate == ao._reserves[asset].currentVariableBorrowRate &&
        
        // Timestamps
        a._reserves[asset].lastUpdateTimestamp == ao._reserves[asset].lastUpdateTimestamp &&
        
        // ID
        a._reserves[asset].id == ao._reserves[asset].id &&
        
        // Addresses
        a._reserves[asset].aTokenAddress == ao._reserves[asset].aTokenAddress &&
        a._reserves[asset].variableDebtTokenAddress == ao._reserves[asset].variableDebtTokenAddress &&
        a._reserves[asset].interestRateStrategyAddress == ao._reserves[asset].interestRateStrategyAddress &&
        
        // Amounts
        a._reserves[asset].accruedToTreasury == ao._reserves[asset].accruedToTreasury &&
        a._reserves[asset].unbacked == ao._reserves[asset].unbacked &&
        a._reserves[asset].isolationModeTotalDebt == ao._reserves[asset].isolationModeTotalDebt &&
        a._reserves[asset].virtualUnderlyingBalance == ao._reserves[asset].virtualUnderlyingBalance &&
        a._reserves[asset].deficit == ao._reserves[asset].deficit &&
        a._reserves[asset].liquidationGracePeriodUntil == ao._reserves[asset].liquidationGracePeriodUntil
    ) &&
    
    // Para cada usuário, as configurações devem ser iguais
    (forall address user.
        a._usersConfig[user].data == ao._usersConfig[user].data &&
        a._usersEModeCategory[user] == ao._usersEModeCategory[user]
    ) &&
    
    // Configurações globais
    a._bridgeProtocolFee == ao._bridgeProtocolFee &&
    a._flashLoanPremiumTotal == ao._flashLoanPremiumTotal &&
    a._flashLoanPremiumToProtocol == ao._flashLoanPremiumToProtocol;


function gasOptimizationCorrectness(method f, method g) {
    env eA;
    env eAo;
    calldataarg args;
    
    require eA == eAo && couplingInv();
    
    a.f(eA, args);
    ao.g(eAo, args);
    
    assert couplingInv();
}

rule gasOptimizedCorrectnessOfSupply(method f, method g)
filtered {
    f -> f.selector == sig:a.supply(address, uint256, address, uint16).selector,
    g -> g.selector == sig:ao.supply(address, uint256, address, uint16).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfWithdraw(method f, method g)
filtered {
    f -> f.selector == sig:a.withdraw(address, uint256, address).selector,
    g -> g.selector == sig:ao.withdraw(address, uint256, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetUserUseReserveAsCollateral(method f, method g)
filtered {
    f -> f.selector == sig:a.setUserUseReserveAsCollateral(address, bool).selector,
    g -> g.selector == sig:ao.setUserUseReserveAsCollateral(address, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfBorrow(method f, method g)
filtered {
    f -> f.selector == sig:a.borrow(address, uint256, uint256, uint16, address).selector,
    g -> g.selector == sig:ao.borrow(address, uint256, uint256, uint16, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfRepay(method f, method g)
filtered {
    f -> f.selector == sig:a.repay(address, uint256, uint256, address).selector,
    g -> g.selector == sig:ao.repay(address, uint256, uint256, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfRepayWithATokens(method f, method g)
filtered {
    f -> f.selector == sig:a.repayWithATokens(address, uint256, uint256).selector,
    g -> g.selector == sig:ao.repayWithATokens(address, uint256, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfLiquidationCall(method f, method g)
filtered {
    f -> f.selector == sig:a.liquidationCall(address, address, address, uint256, bool).selector,
    g -> g.selector == sig:ao.liquidationCall(address, address, address, uint256, bool).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfFlashLoan(method f, method g)
filtered {
    f -> f.selector == sig:a.flashLoan(address, address[], uint256[], uint256[], address, bytes, uint16).selector,
    g -> g.selector == sig:ao.flashLoan(address, address[], uint256[], uint256[], address, bytes, uint16).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfFlashLoanSimple(method f, method g)
filtered {
    f -> f.selector == sig:a.flashLoanSimple(address, address, uint256, bytes, uint16).selector,
    g -> g.selector == sig:ao.flashLoanSimple(address, address, uint256, bytes, uint16).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfInitReserve(method f, method g)
filtered {
    f -> f.selector == sig:a.initReserve(address, address, address, address).selector,
    g -> g.selector == sig:ao.initReserve(address, address, address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDropReserve(method f, method g)
filtered {
    f -> f.selector == sig:a.dropReserve(address).selector,
    g -> g.selector == sig:ao.dropReserve(address).selector
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
    f -> f.selector == sig:a.setConfiguration(address, DataTypes.ReserveConfigurationMap).selector,
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

rule gasOptimizedCorrectnessOfSetUserEMode(method f, method g)
filtered {
    f -> f.selector == sig:a.setUserEMode(uint8).selector,
    g -> g.selector == sig:ao.setUserEMode(uint8).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfConfigureEModeCategory(method f, method g)
filtered {
    f -> f.selector == sig:a.configureEModeCategory(uint8, DataTypes.EModeCategoryBaseConfiguration).selector,
    g -> g.selector == sig:ao.configureEModeCategory(uint8, DataTypes.EModeCategoryBaseConfiguration).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfResetIsolationModeTotalDebt(method f, method g)
filtered {
    f -> f.selector == sig:a.resetIsolationModeTotalDebt(address).selector,
    g -> g.selector == sig:ao.resetIsolationModeTotalDebt(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetLiquidationGracePeriod(method f, method g)
filtered {
    f -> f.selector == sig:a.setLiquidationGracePeriod(address, uint40).selector,
    g -> g.selector == sig:ao.setLiquidationGracePeriod(address, uint40).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfRescueTokens(method f, method g)
filtered {
    f -> f.selector == sig:a.rescueTokens(address, address, uint256).selector,
    g -> g.selector == sig:ao.rescueTokens(address, address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}