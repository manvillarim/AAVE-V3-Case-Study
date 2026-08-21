using ReserveLogicOriginal as a;
using ReserveLogicOptimized as ao;

ghost mapping(address => uint256) ghostScaledTotalSupply;
ghost mapping(uint256 => mapping(uint256 => uint256)) ghostLinearInterest;
ghost mapping(uint256 => mapping(uint256 => uint256)) ghostCompoundedInterest;
ghost mapping(address => uint256) ghostLiquidityRate;
ghost mapping(address => uint256) ghostVariableBorrowRate;

function interestRatesSummary(address strategy) returns (uint256, uint256) {
    return (ghostLiquidityRate[strategy], ghostVariableBorrowRate[strategy]);
}

function linearInterestSummary(uint256 rate, uint40 lastUpdateTimestamp) returns uint256 {
    return ghostLinearInterest[rate][assert_uint256(lastUpdateTimestamp)];
}

function compoundedInterestSummary(uint256 rate, uint40 t0, uint256 t1) returns uint256 {
    return ghostCompoundedInterest[rate][assert_uint256(to_mathint(t1) - to_mathint(t0) < 0 ? 0 : to_mathint(t1) - to_mathint(t0))];
}

ghost mapping(address => uint256) ghost_a_cfg;
hook Sstore a._reserves[KEY address asset].configuration.data uint256 newValue {
    ghost_a_cfg[asset] = newValue;
}
hook Sload uint256 val a._reserves[KEY address asset].configuration.data {
    require ghost_a_cfg[asset] == val;
}

ghost mapping(address => uint128) ghost_a_li;
hook Sstore a._reserves[KEY address asset].liquidityIndex uint128 newValue {
    ghost_a_li[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].liquidityIndex {
    require ghost_a_li[asset] == val;
}

ghost mapping(address => uint128) ghost_a_clr;
hook Sstore a._reserves[KEY address asset].currentLiquidityRate uint128 newValue {
    ghost_a_clr[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].currentLiquidityRate {
    require ghost_a_clr[asset] == val;
}

ghost mapping(address => uint128) ghost_a_vbi;
hook Sstore a._reserves[KEY address asset].variableBorrowIndex uint128 newValue {
    ghost_a_vbi[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].variableBorrowIndex {
    require ghost_a_vbi[asset] == val;
}

ghost mapping(address => uint128) ghost_a_cvbr;
hook Sstore a._reserves[KEY address asset].currentVariableBorrowRate uint128 newValue {
    ghost_a_cvbr[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].currentVariableBorrowRate {
    require ghost_a_cvbr[asset] == val;
}

ghost mapping(address => uint40) ghost_a_lut;
hook Sstore a._reserves[KEY address asset].lastUpdateTimestamp uint40 newValue {
    ghost_a_lut[asset] = newValue;
}
hook Sload uint40 val a._reserves[KEY address asset].lastUpdateTimestamp {
    require ghost_a_lut[asset] == val;
}

ghost mapping(address => uint16) ghost_a_id;
hook Sstore a._reserves[KEY address asset].id uint16 newValue {
    ghost_a_id[asset] = newValue;
}
hook Sload uint16 val a._reserves[KEY address asset].id {
    require ghost_a_id[asset] == val;
}

ghost mapping(address => address) ghost_a_at;
hook Sstore a._reserves[KEY address asset].aTokenAddress address newValue {
    ghost_a_at[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].aTokenAddress {
    require ghost_a_at[asset] == val;
}

ghost mapping(address => address) ghost_a_vdt;
hook Sstore a._reserves[KEY address asset].variableDebtTokenAddress address newValue {
    ghost_a_vdt[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].variableDebtTokenAddress {
    require ghost_a_vdt[asset] == val;
}

ghost mapping(address => address) ghost_a_irs;
hook Sstore a._reserves[KEY address asset].interestRateStrategyAddress address newValue {
    ghost_a_irs[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].interestRateStrategyAddress {
    require ghost_a_irs[asset] == val;
}

ghost mapping(address => uint128) ghost_a_att;
hook Sstore a._reserves[KEY address asset].accruedToTreasury uint128 newValue {
    ghost_a_att[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].accruedToTreasury {
    require ghost_a_att[asset] == val;
}

ghost mapping(address => uint128) ghost_a_vub;
hook Sstore a._reserves[KEY address asset].virtualUnderlyingBalance uint128 newValue {
    ghost_a_vub[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].virtualUnderlyingBalance {
    require ghost_a_vub[asset] == val;
}

ghost mapping(address => uint256) ghost_ao_cfg;
hook Sstore ao._reserves[KEY address asset].configuration.data uint256 newValue {
    ghost_ao_cfg[asset] = newValue;
}
hook Sload uint256 val ao._reserves[KEY address asset].configuration.data {
    require ghost_ao_cfg[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_li;
hook Sstore ao._reserves[KEY address asset].liquidityIndex uint128 newValue {
    ghost_ao_li[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].liquidityIndex {
    require ghost_ao_li[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_clr;
hook Sstore ao._reserves[KEY address asset].currentLiquidityRate uint128 newValue {
    ghost_ao_clr[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].currentLiquidityRate {
    require ghost_ao_clr[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_vbi;
hook Sstore ao._reserves[KEY address asset].variableBorrowIndex uint128 newValue {
    ghost_ao_vbi[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].variableBorrowIndex {
    require ghost_ao_vbi[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_cvbr;
hook Sstore ao._reserves[KEY address asset].currentVariableBorrowRate uint128 newValue {
    ghost_ao_cvbr[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].currentVariableBorrowRate {
    require ghost_ao_cvbr[asset] == val;
}

ghost mapping(address => uint40) ghost_ao_lut;
hook Sstore ao._reserves[KEY address asset].lastUpdateTimestamp uint40 newValue {
    ghost_ao_lut[asset] = newValue;
}
hook Sload uint40 val ao._reserves[KEY address asset].lastUpdateTimestamp {
    require ghost_ao_lut[asset] == val;
}

ghost mapping(address => uint16) ghost_ao_id;
hook Sstore ao._reserves[KEY address asset].id uint16 newValue {
    ghost_ao_id[asset] = newValue;
}
hook Sload uint16 val ao._reserves[KEY address asset].id {
    require ghost_ao_id[asset] == val;
}

ghost mapping(address => address) ghost_ao_at;
hook Sstore ao._reserves[KEY address asset].aTokenAddress address newValue {
    ghost_ao_at[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].aTokenAddress {
    require ghost_ao_at[asset] == val;
}

ghost mapping(address => address) ghost_ao_vdt;
hook Sstore ao._reserves[KEY address asset].variableDebtTokenAddress address newValue {
    ghost_ao_vdt[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].variableDebtTokenAddress {
    require ghost_ao_vdt[asset] == val;
}

ghost mapping(address => address) ghost_ao_irs;
hook Sstore ao._reserves[KEY address asset].interestRateStrategyAddress address newValue {
    ghost_ao_irs[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].interestRateStrategyAddress {
    require ghost_ao_irs[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_att;
hook Sstore ao._reserves[KEY address asset].accruedToTreasury uint128 newValue {
    ghost_ao_att[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].accruedToTreasury {
    require ghost_ao_att[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_vub;
hook Sstore ao._reserves[KEY address asset].virtualUnderlyingBalance uint128 newValue {
    ghost_ao_vub[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].virtualUnderlyingBalance {
    require ghost_ao_vub[asset] == val;
}
