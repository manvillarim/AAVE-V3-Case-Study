using RewardsControllerOriginal as a;
using RewardsControllerOptimized as ao;

ghost mapping(address => address) ghost_a_authorizedClaimers {
    init_state axiom forall address user.
        ghost_a_authorizedClaimers[user] == 0;
}

ghost mapping(address => address) ghost_a_transferStrategy {
    init_state axiom forall address reward.
        ghost_a_transferStrategy[reward] == 0;
}

ghost mapping(address => address) ghost_a_rewardOracle {
    init_state axiom forall address reward.
        ghost_a_rewardOracle[reward] == 0;
}

ghost mapping(address => mapping(address => mapping(address => uint104))) ghost_a_userIndex {
    init_state axiom forall address asset. forall address reward. forall address user.
        ghost_a_userIndex[asset][reward][user] == 0;
}

ghost mapping(address => mapping(address => mapping(address => uint128))) ghost_a_userAccrued {
    init_state axiom forall address asset. forall address reward. forall address user.
        ghost_a_userAccrued[asset][reward][user] == 0;
}

ghost mapping(address => mapping(address => uint104)) ghost_a_rewardIndex {
    init_state axiom forall address asset. forall address reward.
        ghost_a_rewardIndex[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint88)) ghost_a_emissionPerSecond {
    init_state axiom forall address asset. forall address reward.
        ghost_a_emissionPerSecond[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint32)) ghost_a_lastUpdateTimestamp {
    init_state axiom forall address asset. forall address reward.
        ghost_a_lastUpdateTimestamp[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint32)) ghost_a_distributionEnd {
    init_state axiom forall address asset. forall address reward.
        ghost_a_distributionEnd[asset][reward] == 0;
}

ghost mapping(address => uint8) ghost_a_assetDecimals {
    init_state axiom forall address asset.
        ghost_a_assetDecimals[asset] == 0;
}

ghost mapping(address => uint128) ghost_a_availableRewardsCount {
    init_state axiom forall address asset.
        ghost_a_availableRewardsCount[asset] == 0;
}

ghost mapping(address => mapping(uint128 => address)) ghost_a_availableRewards {
    init_state axiom forall address asset. forall uint128 idx.
        ghost_a_availableRewards[asset][idx] == 0;
}

ghost mapping(address => bool) ghost_a_isRewardEnabled {
    init_state axiom forall address reward.
        ghost_a_isRewardEnabled[reward] == false;
}

ghost uint256 ghost_a_rewardsListLength {
    init_state axiom ghost_a_rewardsListLength == 0;
}

ghost mapping(uint256 => address) ghost_a_rewardsListAt {
    init_state axiom forall uint256 idx.
        ghost_a_rewardsListAt[idx] == 0;
}

ghost uint256 ghost_a_assetsListLength {
    init_state axiom ghost_a_assetsListLength == 0;
}

ghost mapping(uint256 => address) ghost_a_assetsListAt {
    init_state axiom forall uint256 idx.
        ghost_a_assetsListAt[idx] == 0;
}

ghost mapping(address => address) ghost_ao_authorizedClaimers {
    init_state axiom forall address user.
        ghost_ao_authorizedClaimers[user] == 0;
}

ghost mapping(address => address) ghost_ao_transferStrategy {
    init_state axiom forall address reward.
        ghost_ao_transferStrategy[reward] == 0;
}

ghost mapping(address => address) ghost_ao_rewardOracle {
    init_state axiom forall address reward.
        ghost_ao_rewardOracle[reward] == 0;
}

ghost mapping(address => mapping(address => mapping(address => uint104))) ghost_ao_userIndex {
    init_state axiom forall address asset. forall address reward. forall address user.
        ghost_ao_userIndex[asset][reward][user] == 0;
}

ghost mapping(address => mapping(address => mapping(address => uint128))) ghost_ao_userAccrued {
    init_state axiom forall address asset. forall address reward. forall address user.
        ghost_ao_userAccrued[asset][reward][user] == 0;
}

ghost mapping(address => mapping(address => uint104)) ghost_ao_rewardIndex {
    init_state axiom forall address asset. forall address reward.
        ghost_ao_rewardIndex[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint88)) ghost_ao_emissionPerSecond {
    init_state axiom forall address asset. forall address reward.
        ghost_ao_emissionPerSecond[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint32)) ghost_ao_lastUpdateTimestamp {
    init_state axiom forall address asset. forall address reward.
        ghost_ao_lastUpdateTimestamp[asset][reward] == 0;
}

ghost mapping(address => mapping(address => uint32)) ghost_ao_distributionEnd {
    init_state axiom forall address asset. forall address reward.
        ghost_ao_distributionEnd[asset][reward] == 0;
}

ghost mapping(address => uint8) ghost_ao_assetDecimals {
    init_state axiom forall address asset.
        ghost_ao_assetDecimals[asset] == 0;
}

ghost mapping(address => uint128) ghost_ao_availableRewardsCount {
    init_state axiom forall address asset.
        ghost_ao_availableRewardsCount[asset] == 0;
}

ghost mapping(address => mapping(uint128 => address)) ghost_ao_availableRewards {
    init_state axiom forall address asset. forall uint128 idx.
        ghost_ao_availableRewards[asset][idx] == 0;
}

ghost mapping(address => bool) ghost_ao_isRewardEnabled {
    init_state axiom forall address reward.
        ghost_ao_isRewardEnabled[reward] == false;
}

ghost uint256 ghost_ao_rewardsListLength {
    init_state axiom ghost_ao_rewardsListLength == 0;
}

ghost mapping(uint256 => address) ghost_ao_rewardsListAt {
    init_state axiom forall uint256 idx.
        ghost_ao_rewardsListAt[idx] == 0;
}

ghost uint256 ghost_ao_assetsListLength {
    init_state axiom ghost_ao_assetsListLength == 0;
}

ghost mapping(uint256 => address) ghost_ao_assetsListAt {
    init_state axiom forall uint256 idx.
        ghost_ao_assetsListAt[idx] == 0;
}

ghost mapping(address => uint256) ghostScaledTotalSupply {
    init_state axiom forall address asset. 
        ghostScaledTotalSupply[asset] >= 1000000 && 
        ghostScaledTotalSupply[asset] <= 10^30;
}

ghost mapping(address => mapping(address => uint256)) ghostScaledBalanceOf {
    init_state axiom forall address asset. forall address user.
        ghostScaledBalanceOf[asset][user] >= 0 && 
        ghostScaledBalanceOf[asset][user] <= ghostScaledTotalSupply[asset];
}

ghost mapping(address => uint8) ghostDecimalsMapping {
    init_state axiom forall address asset.
        ghostDecimalsMapping[asset] >= 6 &&
        ghostDecimalsMapping[asset] <= 18;
}

function ghostGetScaledUserBalanceAndSupply(address asset, address user) returns (uint256, uint256) {
    return (ghostScaledBalanceOf[asset][user], ghostScaledTotalSupply[asset]);
}

function ghostPerformTransfer(address strategy) returns bool {
    return true;
}

function ghostLatestAnswer(address oracle) returns int256 {
    return 100000000;
}

function ghostDecimals(address asset) returns uint8 {
    return ghostDecimalsMapping[asset];
}

hook Sstore a._authorizedClaimers[KEY address user] address newValue (address oldValue) {
    ghost_a_authorizedClaimers[user] = newValue;
}

hook Sload address val a._authorizedClaimers[KEY address user] {
    require ghost_a_authorizedClaimers[user] == val;
}

hook Sstore a._transferStrategy[KEY address reward] address newValue (address oldValue) {
    ghost_a_transferStrategy[reward] = newValue;
}

hook Sload address val a._transferStrategy[KEY address reward] {
    require ghost_a_transferStrategy[reward] == val;
}

hook Sstore a._rewardOracle[KEY address reward] address newValue (address oldValue) {
    ghost_a_rewardOracle[reward] = newValue;
}

hook Sload address val a._rewardOracle[KEY address reward] {
    require ghost_a_rewardOracle[reward] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].index uint104 newValue (uint104 oldValue) {
    ghost_a_userIndex[asset][reward][user] = newValue;
}

hook Sload uint104 val a._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].index {
    require ghost_a_userIndex[asset][reward][user] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].accrued uint128 newValue (uint128 oldValue) {
    ghost_a_userAccrued[asset][reward][user] = newValue;
}

hook Sload uint128 val a._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].accrued {
    require ghost_a_userAccrued[asset][reward][user] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].index uint104 newValue (uint104 oldValue) {
    ghost_a_rewardIndex[asset][reward] = newValue;
}

hook Sload uint104 val a._assets[KEY address asset].rewards[KEY address reward].index {
    require ghost_a_rewardIndex[asset][reward] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].emissionPerSecond uint88 newValue (uint88 oldValue) {
    ghost_a_emissionPerSecond[asset][reward] = newValue;
}

hook Sload uint88 val a._assets[KEY address asset].rewards[KEY address reward].emissionPerSecond {
    require ghost_a_emissionPerSecond[asset][reward] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].lastUpdateTimestamp uint32 newValue (uint32 oldValue) {
    ghost_a_lastUpdateTimestamp[asset][reward] = newValue;
}

hook Sload uint32 val a._assets[KEY address asset].rewards[KEY address reward].lastUpdateTimestamp {
    require ghost_a_lastUpdateTimestamp[asset][reward] == val;
}

hook Sstore a._assets[KEY address asset].rewards[KEY address reward].distributionEnd uint32 newValue (uint32 oldValue) {
    ghost_a_distributionEnd[asset][reward] = newValue;
}

hook Sload uint32 val a._assets[KEY address asset].rewards[KEY address reward].distributionEnd {
    require ghost_a_distributionEnd[asset][reward] == val;
}

hook Sstore a._assets[KEY address asset].decimals uint8 newValue (uint8 oldValue) {
    ghost_a_assetDecimals[asset] = newValue;
}

hook Sload uint8 val a._assets[KEY address asset].decimals {
    require ghost_a_assetDecimals[asset] == val;
}

hook Sstore a._assets[KEY address asset].availableRewardsCount uint128 newValue (uint128 oldValue) {
    ghost_a_availableRewardsCount[asset] = newValue;
}

hook Sload uint128 val a._assets[KEY address asset].availableRewardsCount {
    require ghost_a_availableRewardsCount[asset] == val;
}

hook Sstore a._assets[KEY address asset].availableRewards[KEY uint128 idx] address newValue (address oldValue) {
    ghost_a_availableRewards[asset][idx] = newValue;
}

hook Sload address val a._assets[KEY address asset].availableRewards[KEY uint128 idx] {
    require ghost_a_availableRewards[asset][idx] == val;
}

hook Sstore a._isRewardEnabled[KEY address reward] bool newValue (bool oldValue) {
    ghost_a_isRewardEnabled[reward] = newValue;
}

hook Sload bool val a._isRewardEnabled[KEY address reward] {
    require ghost_a_isRewardEnabled[reward] == val;
}

hook Sstore a._rewardsList[INDEX uint256 idx] address newValue (address oldValue) {
    ghost_a_rewardsListAt[idx] = newValue;
}

hook Sload address val a._rewardsList[INDEX uint256 idx] {
    require ghost_a_rewardsListAt[idx] == val;
}

hook Sstore a._rewardsList.(offset 0) uint256 newLength {
    ghost_a_rewardsListLength = newLength;
}

hook Sload uint256 length a._rewardsList.(offset 0) {
    require ghost_a_rewardsListLength == length;
}

hook Sstore a._assetsList[INDEX uint256 idx] address newValue (address oldValue) {
    ghost_a_assetsListAt[idx] = newValue;
}

hook Sload address val a._assetsList[INDEX uint256 idx] {
    require ghost_a_assetsListAt[idx] == val;
}

hook Sstore a._assetsList.(offset 0) uint256 newLength {
    ghost_a_assetsListLength = newLength;
}

hook Sload uint256 length a._assetsList.(offset 0) {
    require ghost_a_assetsListLength == length;
}

hook Sstore ao._authorizedClaimers[KEY address user] address newValue (address oldValue) {
    ghost_ao_authorizedClaimers[user] = newValue;
}

hook Sload address val ao._authorizedClaimers[KEY address user] {
    require ghost_ao_authorizedClaimers[user] == val;
}

hook Sstore ao._transferStrategy[KEY address reward] address newValue (address oldValue) {
    ghost_ao_transferStrategy[reward] = newValue;
}

hook Sload address val ao._transferStrategy[KEY address reward] {
    require ghost_ao_transferStrategy[reward] == val;
}

hook Sstore ao._rewardOracle[KEY address reward] address newValue (address oldValue) {
    ghost_ao_rewardOracle[reward] = newValue;
}

hook Sload address val ao._rewardOracle[KEY address reward] {
    require ghost_ao_rewardOracle[reward] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].index uint104 newValue (uint104 oldValue) {
    ghost_ao_userIndex[asset][reward][user] = newValue;
}

hook Sload uint104 val ao._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].index {
    require ghost_ao_userIndex[asset][reward][user] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].accrued uint128 newValue (uint128 oldValue) {
    ghost_ao_userAccrued[asset][reward][user] = newValue;
}

hook Sload uint128 val ao._assets[KEY address asset].rewards[KEY address reward].usersData[KEY address user].accrued {
    require ghost_ao_userAccrued[asset][reward][user] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].index uint104 newValue (uint104 oldValue) {
    ghost_ao_rewardIndex[asset][reward] = newValue;
}

hook Sload uint104 val ao._assets[KEY address asset].rewards[KEY address reward].index {
    require ghost_ao_rewardIndex[asset][reward] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].emissionPerSecond uint88 newValue (uint88 oldValue) {
    ghost_ao_emissionPerSecond[asset][reward] = newValue;
}

hook Sload uint88 val ao._assets[KEY address asset].rewards[KEY address reward].emissionPerSecond {
    require ghost_ao_emissionPerSecond[asset][reward] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].lastUpdateTimestamp uint32 newValue (uint32 oldValue) {
    ghost_ao_lastUpdateTimestamp[asset][reward] = newValue;
}

hook Sload uint32 val ao._assets[KEY address asset].rewards[KEY address reward].lastUpdateTimestamp {
    require ghost_ao_lastUpdateTimestamp[asset][reward] == val;
}

hook Sstore ao._assets[KEY address asset].rewards[KEY address reward].distributionEnd uint32 newValue (uint32 oldValue) {
    ghost_ao_distributionEnd[asset][reward] = newValue;
}

hook Sload uint32 val ao._assets[KEY address asset].rewards[KEY address reward].distributionEnd {
    require ghost_ao_distributionEnd[asset][reward] == val;
}

hook Sstore ao._assets[KEY address asset].decimals uint8 newValue (uint8 oldValue) {
    ghost_ao_assetDecimals[asset] = newValue;
}

hook Sload uint8 val ao._assets[KEY address asset].decimals {
    require ghost_ao_assetDecimals[asset] == val;
}

hook Sstore ao._assets[KEY address asset].availableRewardsCount uint128 newValue (uint128 oldValue) {
    ghost_ao_availableRewardsCount[asset] = newValue;
}

hook Sload uint128 val ao._assets[KEY address asset].availableRewardsCount {
    require ghost_ao_availableRewardsCount[asset] == val;
}

hook Sstore ao._assets[KEY address asset].availableRewards[KEY uint128 idx] address newValue (address oldValue) {
    ghost_ao_availableRewards[asset][idx] = newValue;
}

hook Sload address val ao._assets[KEY address asset].availableRewards[KEY uint128 idx] {
    require ghost_ao_availableRewards[asset][idx] == val;
}

hook Sstore ao._isRewardEnabled[KEY address reward] bool newValue (bool oldValue) {
    ghost_ao_isRewardEnabled[reward] = newValue;
}

hook Sload bool val ao._isRewardEnabled[KEY address reward] {
    require ghost_ao_isRewardEnabled[reward] == val;
}

hook Sstore ao._rewardsList[INDEX uint256 idx] address newValue (address oldValue) {
    ghost_ao_rewardsListAt[idx] = newValue;
}

hook Sload address val ao._rewardsList[INDEX uint256 idx] {
    require ghost_ao_rewardsListAt[idx] == val;
}

hook Sstore ao._rewardsList.(offset 0) uint256 newLength {
    ghost_ao_rewardsListLength = newLength;
}

hook Sload uint256 length ao._rewardsList.(offset 0) {
    require ghost_ao_rewardsListLength == length;
}

hook Sstore ao._assetsList[INDEX uint256 idx] address newValue (address oldValue) {
    ghost_ao_assetsListAt[idx] = newValue;
}

hook Sload address val ao._assetsList[INDEX uint256 idx] {
    require ghost_ao_assetsListAt[idx] == val;
}

hook Sstore ao._assetsList.(offset 0) uint256 newLength {
    ghost_ao_assetsListLength = newLength;
}

hook Sload uint256 length ao._assetsList.(offset 0) {
    require ghost_ao_assetsListLength == length;
}