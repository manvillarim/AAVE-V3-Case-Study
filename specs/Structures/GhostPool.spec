using PoolOriginal as a;
using PoolOptimized as ao;

ghost mapping(address => address) ghostProviderAddress;
ghost mapping(address => address) ghostPoolConfigurator;

ghost mapping(address => uint256) ghost_a_r_cfg;
hook Sstore a._reserves[KEY address asset].configuration.data uint256 newValue {
    ghost_a_r_cfg[asset] = newValue;
}
hook Sload uint256 val a._reserves[KEY address asset].configuration.data {
    require ghost_a_r_cfg[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_li;
hook Sstore a._reserves[KEY address asset].liquidityIndex uint128 newValue {
    ghost_a_r_li[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].liquidityIndex {
    require ghost_a_r_li[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_clr;
hook Sstore a._reserves[KEY address asset].currentLiquidityRate uint128 newValue {
    ghost_a_r_clr[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].currentLiquidityRate {
    require ghost_a_r_clr[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_vbi;
hook Sstore a._reserves[KEY address asset].variableBorrowIndex uint128 newValue {
    ghost_a_r_vbi[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].variableBorrowIndex {
    require ghost_a_r_vbi[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_cvbr;
hook Sstore a._reserves[KEY address asset].currentVariableBorrowRate uint128 newValue {
    ghost_a_r_cvbr[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].currentVariableBorrowRate {
    require ghost_a_r_cvbr[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_def;
hook Sstore a._reserves[KEY address asset].deficit uint128 newValue {
    ghost_a_r_def[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].deficit {
    require ghost_a_r_def[asset] == val;
}

ghost mapping(address => uint40) ghost_a_r_lut;
hook Sstore a._reserves[KEY address asset].lastUpdateTimestamp uint40 newValue {
    ghost_a_r_lut[asset] = newValue;
}
hook Sload uint40 val a._reserves[KEY address asset].lastUpdateTimestamp {
    require ghost_a_r_lut[asset] == val;
}

ghost mapping(address => uint16) ghost_a_r_id;
hook Sstore a._reserves[KEY address asset].id uint16 newValue {
    ghost_a_r_id[asset] = newValue;
}
hook Sload uint16 val a._reserves[KEY address asset].id {
    require ghost_a_r_id[asset] == val;
}

ghost mapping(address => uint40) ghost_a_r_lgp;
hook Sstore a._reserves[KEY address asset].liquidationGracePeriodUntil uint40 newValue {
    ghost_a_r_lgp[asset] = newValue;
}
hook Sload uint40 val a._reserves[KEY address asset].liquidationGracePeriodUntil {
    require ghost_a_r_lgp[asset] == val;
}

ghost mapping(address => address) ghost_a_r_at;
hook Sstore a._reserves[KEY address asset].aTokenAddress address newValue {
    ghost_a_r_at[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].aTokenAddress {
    require ghost_a_r_at[asset] == val;
}

ghost mapping(address => address) ghost_a_r_vdt;
hook Sstore a._reserves[KEY address asset].variableDebtTokenAddress address newValue {
    ghost_a_r_vdt[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].variableDebtTokenAddress {
    require ghost_a_r_vdt[asset] == val;
}

ghost mapping(address => address) ghost_a_r_irs;
hook Sstore a._reserves[KEY address asset].interestRateStrategyAddress address newValue {
    ghost_a_r_irs[asset] = newValue;
}
hook Sload address val a._reserves[KEY address asset].interestRateStrategyAddress {
    require ghost_a_r_irs[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_att;
hook Sstore a._reserves[KEY address asset].accruedToTreasury uint128 newValue {
    ghost_a_r_att[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].accruedToTreasury {
    require ghost_a_r_att[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_unb;
hook Sstore a._reserves[KEY address asset].unbacked uint128 newValue {
    ghost_a_r_unb[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].unbacked {
    require ghost_a_r_unb[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_imtd;
hook Sstore a._reserves[KEY address asset].isolationModeTotalDebt uint128 newValue {
    ghost_a_r_imtd[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].isolationModeTotalDebt {
    require ghost_a_r_imtd[asset] == val;
}

ghost mapping(address => uint128) ghost_a_r_vub;
hook Sstore a._reserves[KEY address asset].virtualUnderlyingBalance uint128 newValue {
    ghost_a_r_vub[asset] = newValue;
}
hook Sload uint128 val a._reserves[KEY address asset].virtualUnderlyingBalance {
    require ghost_a_r_vub[asset] == val;
}

ghost mapping(uint8 => uint16) ghost_a_e_ltv;
hook Sstore a._eModeCategories[KEY uint8 id].ltv uint16 newValue {
    ghost_a_e_ltv[id] = newValue;
}
hook Sload uint16 val a._eModeCategories[KEY uint8 id].ltv {
    require ghost_a_e_ltv[id] == val;
}

ghost mapping(uint8 => uint16) ghost_a_e_lt;
hook Sstore a._eModeCategories[KEY uint8 id].liquidationThreshold uint16 newValue {
    ghost_a_e_lt[id] = newValue;
}
hook Sload uint16 val a._eModeCategories[KEY uint8 id].liquidationThreshold {
    require ghost_a_e_lt[id] == val;
}

ghost mapping(uint8 => uint16) ghost_a_e_lb;
hook Sstore a._eModeCategories[KEY uint8 id].liquidationBonus uint16 newValue {
    ghost_a_e_lb[id] = newValue;
}
hook Sload uint16 val a._eModeCategories[KEY uint8 id].liquidationBonus {
    require ghost_a_e_lb[id] == val;
}

ghost mapping(uint8 => uint128) ghost_a_e_cbm;
hook Sstore a._eModeCategories[KEY uint8 id].collateralBitmap uint128 newValue {
    ghost_a_e_cbm[id] = newValue;
}
hook Sload uint128 val a._eModeCategories[KEY uint8 id].collateralBitmap {
    require ghost_a_e_cbm[id] == val;
}

ghost mapping(uint8 => uint128) ghost_a_e_bbm;
hook Sstore a._eModeCategories[KEY uint8 id].borrowableBitmap uint128 newValue {
    ghost_a_e_bbm[id] = newValue;
}
hook Sload uint128 val a._eModeCategories[KEY uint8 id].borrowableBitmap {
    require ghost_a_e_bbm[id] == val;
}

ghost mapping(uint8 => bytes32) ghost_a_e_label;
hook Sstore a._eModeCategories[KEY uint8 id].(offset 32) bytes32 newValue {
    ghost_a_e_label[id] = newValue;
}
hook Sload bytes32 val a._eModeCategories[KEY uint8 id].(offset 32) {
    require ghost_a_e_label[id] == val;
}


ghost mapping(address => uint256) ghost_a_uc;
hook Sstore a._usersConfig[KEY address user].data uint256 newValue {
    ghost_a_uc[user] = newValue;
}
hook Sload uint256 val a._usersConfig[KEY address user].data {
    require ghost_a_uc[user] == val;
}

ghost mapping(address => uint8) ghost_a_uem;
hook Sstore a._usersEModeCategory[KEY address user] uint8 newValue {
    ghost_a_uem[user] = newValue;
}
hook Sload uint8 val a._usersEModeCategory[KEY address user] {
    require ghost_a_uem[user] == val;
}

ghost mapping(uint256 => address) ghost_a_rl;
hook Sstore a._reservesList[KEY uint256 i] address newValue {
    ghost_a_rl[i] = newValue;
}
hook Sload address val a._reservesList[KEY uint256 i] {
    require ghost_a_rl[i] == val;
}

ghost mapping(uint256 => address) ghost_a_lrl;
hook Sstore a.lastReservesList[KEY uint256 i] address newValue {
    ghost_a_lrl[i] = newValue;
}
hook Sload address val a.lastReservesList[KEY uint256 i] {
    require ghost_a_lrl[i] == val;
}

ghost mapping(address => uint256) ghost_ao_r_cfg;
hook Sstore ao._reserves[KEY address asset].configuration.data uint256 newValue {
    ghost_ao_r_cfg[asset] = newValue;
}
hook Sload uint256 val ao._reserves[KEY address asset].configuration.data {
    require ghost_ao_r_cfg[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_li;
hook Sstore ao._reserves[KEY address asset].liquidityIndex uint128 newValue {
    ghost_ao_r_li[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].liquidityIndex {
    require ghost_ao_r_li[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_clr;
hook Sstore ao._reserves[KEY address asset].currentLiquidityRate uint128 newValue {
    ghost_ao_r_clr[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].currentLiquidityRate {
    require ghost_ao_r_clr[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_vbi;
hook Sstore ao._reserves[KEY address asset].variableBorrowIndex uint128 newValue {
    ghost_ao_r_vbi[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].variableBorrowIndex {
    require ghost_ao_r_vbi[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_cvbr;
hook Sstore ao._reserves[KEY address asset].currentVariableBorrowRate uint128 newValue {
    ghost_ao_r_cvbr[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].currentVariableBorrowRate {
    require ghost_ao_r_cvbr[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_def;
hook Sstore ao._reserves[KEY address asset].deficit uint128 newValue {
    ghost_ao_r_def[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].deficit {
    require ghost_ao_r_def[asset] == val;
}

ghost mapping(address => uint40) ghost_ao_r_lut;
hook Sstore ao._reserves[KEY address asset].lastUpdateTimestamp uint40 newValue {
    ghost_ao_r_lut[asset] = newValue;
}
hook Sload uint40 val ao._reserves[KEY address asset].lastUpdateTimestamp {
    require ghost_ao_r_lut[asset] == val;
}

ghost mapping(address => uint16) ghost_ao_r_id;
hook Sstore ao._reserves[KEY address asset].id uint16 newValue {
    ghost_ao_r_id[asset] = newValue;
}
hook Sload uint16 val ao._reserves[KEY address asset].id {
    require ghost_ao_r_id[asset] == val;
}

ghost mapping(address => uint40) ghost_ao_r_lgp;
hook Sstore ao._reserves[KEY address asset].liquidationGracePeriodUntil uint40 newValue {
    ghost_ao_r_lgp[asset] = newValue;
}
hook Sload uint40 val ao._reserves[KEY address asset].liquidationGracePeriodUntil {
    require ghost_ao_r_lgp[asset] == val;
}

ghost mapping(address => address) ghost_ao_r_at;
hook Sstore ao._reserves[KEY address asset].aTokenAddress address newValue {
    ghost_ao_r_at[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].aTokenAddress {
    require ghost_ao_r_at[asset] == val;
}

ghost mapping(address => address) ghost_ao_r_vdt;
hook Sstore ao._reserves[KEY address asset].variableDebtTokenAddress address newValue {
    ghost_ao_r_vdt[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].variableDebtTokenAddress {
    require ghost_ao_r_vdt[asset] == val;
}

ghost mapping(address => address) ghost_ao_r_irs;
hook Sstore ao._reserves[KEY address asset].interestRateStrategyAddress address newValue {
    ghost_ao_r_irs[asset] = newValue;
}
hook Sload address val ao._reserves[KEY address asset].interestRateStrategyAddress {
    require ghost_ao_r_irs[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_att;
hook Sstore ao._reserves[KEY address asset].accruedToTreasury uint128 newValue {
    ghost_ao_r_att[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].accruedToTreasury {
    require ghost_ao_r_att[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_unb;
hook Sstore ao._reserves[KEY address asset].unbacked uint128 newValue {
    ghost_ao_r_unb[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].unbacked {
    require ghost_ao_r_unb[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_imtd;
hook Sstore ao._reserves[KEY address asset].isolationModeTotalDebt uint128 newValue {
    ghost_ao_r_imtd[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].isolationModeTotalDebt {
    require ghost_ao_r_imtd[asset] == val;
}

ghost mapping(address => uint128) ghost_ao_r_vub;
hook Sstore ao._reserves[KEY address asset].virtualUnderlyingBalance uint128 newValue {
    ghost_ao_r_vub[asset] = newValue;
}
hook Sload uint128 val ao._reserves[KEY address asset].virtualUnderlyingBalance {
    require ghost_ao_r_vub[asset] == val;
}

ghost mapping(uint8 => uint16) ghost_ao_e_ltv;
hook Sstore ao._eModeCategories[KEY uint8 id].ltv uint16 newValue {
    ghost_ao_e_ltv[id] = newValue;
}
hook Sload uint16 val ao._eModeCategories[KEY uint8 id].ltv {
    require ghost_ao_e_ltv[id] == val;
}

ghost mapping(uint8 => uint16) ghost_ao_e_lt;
hook Sstore ao._eModeCategories[KEY uint8 id].liquidationThreshold uint16 newValue {
    ghost_ao_e_lt[id] = newValue;
}
hook Sload uint16 val ao._eModeCategories[KEY uint8 id].liquidationThreshold {
    require ghost_ao_e_lt[id] == val;
}

ghost mapping(uint8 => uint16) ghost_ao_e_lb;
hook Sstore ao._eModeCategories[KEY uint8 id].liquidationBonus uint16 newValue {
    ghost_ao_e_lb[id] = newValue;
}
hook Sload uint16 val ao._eModeCategories[KEY uint8 id].liquidationBonus {
    require ghost_ao_e_lb[id] == val;
}

ghost mapping(uint8 => uint128) ghost_ao_e_cbm;
hook Sstore ao._eModeCategories[KEY uint8 id].collateralBitmap uint128 newValue {
    ghost_ao_e_cbm[id] = newValue;
}
hook Sload uint128 val ao._eModeCategories[KEY uint8 id].collateralBitmap {
    require ghost_ao_e_cbm[id] == val;
}

ghost mapping(uint8 => uint128) ghost_ao_e_bbm;
hook Sstore ao._eModeCategories[KEY uint8 id].borrowableBitmap uint128 newValue {
    ghost_ao_e_bbm[id] = newValue;
}
hook Sload uint128 val ao._eModeCategories[KEY uint8 id].borrowableBitmap {
    require ghost_ao_e_bbm[id] == val;
}

ghost mapping(uint8 => bytes32) ghost_ao_e_label;
hook Sstore ao._eModeCategories[KEY uint8 id].(offset 32) bytes32 newValue {
    ghost_ao_e_label[id] = newValue;
}
hook Sload bytes32 val ao._eModeCategories[KEY uint8 id].(offset 32) {
    require ghost_ao_e_label[id] == val;
}


ghost mapping(address => uint256) ghost_ao_uc;
hook Sstore ao._usersConfig[KEY address user].data uint256 newValue {
    ghost_ao_uc[user] = newValue;
}
hook Sload uint256 val ao._usersConfig[KEY address user].data {
    require ghost_ao_uc[user] == val;
}

ghost mapping(address => uint8) ghost_ao_uem;
hook Sstore ao._usersEModeCategory[KEY address user] uint8 newValue {
    ghost_ao_uem[user] = newValue;
}
hook Sload uint8 val ao._usersEModeCategory[KEY address user] {
    require ghost_ao_uem[user] == val;
}

ghost mapping(uint256 => address) ghost_ao_rl;
hook Sstore ao._reservesList[KEY uint256 i] address newValue {
    ghost_ao_rl[i] = newValue;
}
hook Sload address val ao._reservesList[KEY uint256 i] {
    require ghost_ao_rl[i] == val;
}

ghost mapping(uint256 => address) ghost_ao_lrl;
hook Sstore ao.lastReservesList[KEY uint256 i] address newValue {
    ghost_ao_lrl[i] = newValue;
}
hook Sload address val ao.lastReservesList[KEY uint256 i] {
    require ghost_ao_lrl[i] == val;
}
