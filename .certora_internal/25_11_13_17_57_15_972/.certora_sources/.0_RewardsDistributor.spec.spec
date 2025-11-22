import "Structures/GhostsRewardsDistributor.spec";

using RewardsDistributorOriginal as a;
using RewardsDistributorOptimized as ao;

methods {
    function _.scaledTotalSupply() external => ghostScaledTotalSupply[calledContract] expect uint256 ALL;
    function _.scaledBalanceOf(address) external => ghostScaledBalanceOf[calledContract][calledContract] expect uint256 ALL;
    
    function a.getUserAccruedRewards(address, address) external returns (uint256) envfree;
    function ao.getUserAccruedRewards(address, address) external returns (uint256) envfree;
    
    function a.getRewardsData(address, address) external returns (uint256, uint256, uint256, uint256) envfree;
    function ao.getRewardsData(address, address) external returns (uint256, uint256, uint256, uint256) envfree;
    
    function a.getDistributionEnd(address, address) external returns (uint256) envfree;
    function ao.getDistributionEnd(address, address) external returns (uint256) envfree;
    
    function a.getRewardsByAsset(address) external returns (address[]) envfree;
    function ao.getRewardsByAsset(address) external returns (address[]) envfree;
    
    function a.getRewardsList() external returns (address[]) envfree;
    function ao.getRewardsList() external returns (address[]) envfree;
    
    function a.getUserAssetIndex(address, address, address) external returns (uint256) envfree;
    function ao.getUserAssetIndex(address, address, address) external returns (uint256) envfree;
    
    function a.getAssetDecimals(address) external returns (uint8) envfree;
    function ao.getAssetDecimals(address) external returns (uint8) envfree;
    
    function a.getEmissionManager() external returns (address) envfree;
    function ao.getEmissionManager() external returns (address) envfree;
}

definition CouplingInv() returns bool =
    a.EMISSION_MANAGER == ao.EMISSION_MANAGER &&
    
    (forall address asset. forall address reward. forall address user.
        ghost_a_userIndex[asset][reward][user] == ghost_ao_userIndex[asset][reward][user] &&
        ghost_a_userAccrued[asset][reward][user] == ghost_ao_userAccrued[asset][reward][user]
    ) &&
    
    (forall address asset. forall address reward.
        ghost_a_rewardIndex[asset][reward] == ghost_ao_rewardIndex[asset][reward] &&
        ghost_a_emissionPerSecond[asset][reward] == ghost_ao_emissionPerSecond[asset][reward] &&
        ghost_a_lastUpdateTimestamp[asset][reward] == ghost_ao_lastUpdateTimestamp[asset][reward] &&
        ghost_a_distributionEnd[asset][reward] == ghost_ao_distributionEnd[asset][reward]
    ) &&
    
    (forall address asset.
        ghost_a_assetDecimals[asset] == ghost_ao_assetDecimals[asset] &&
        ghost_a_availableRewardsCount[asset] == ghost_ao_availableRewardsCount[asset]
    ) &&
    
    (forall address asset. forall uint128 idx.
        idx < ghost_a_availableRewardsCount[asset] => 
        ghost_a_availableRewards[asset][idx] == ghost_ao_availableRewards[asset][idx]
    ) &&
    
    (forall address reward.
        ghost_a_isRewardEnabled[reward] == ghost_ao_isRewardEnabled[reward]
    ) &&
    
    ghost_a_rewardsListLength == ghost_ao_rewardsListLength &&
    (forall uint256 idx.
        idx < ghost_a_rewardsListLength =>
        ghost_a_rewardsListAt[idx] == ghost_ao_rewardsListAt[idx]
    ) &&
    
    ghost_a_assetsListLength == ghost_ao_assetsListLength &&
    (forall uint256 idx.
        idx < ghost_a_assetsListLength =>
        ghost_a_assetsListAt[idx] == ghost_ao_assetsListAt[idx]
    );

function gasOptimizationCorrectness(method f, method g) {
    env eA;
    env eAo;
    calldataarg args;
    
    require eA == eAo && CouplingInv();
    require forall address asset. 
        ghostScaledTotalSupply[asset] == ghostScaledTotalSupply[asset];

    a.f@withrevert(eA, args);
    bool a_reverted = lastReverted;

    ao.g@withrevert(eAo, args);
    bool ao_reverted = lastReverted;

    assert a_reverted == ao_reverted;
    assert CouplingInv();
}

rule gasOptimizedCorrectnessOfSetEmissionPerSecond(method f, method g)
filtered {
    f -> f.selector == sig:a.setEmissionPerSecond(address, address[], uint88[]).selector,
    g -> g.selector == sig:ao.setEmissionPerSecond(address, address[], uint88[]).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetUserAccruedRewards(method f, method g)
filtered {
    f -> f.selector == sig:a.getUserAccruedRewards(address, address).selector,
    g -> g.selector == sig:ao.getUserAccruedRewards(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetAllUserRewards(method f, method g)
filtered {
    f -> f.selector == sig:a.getAllUserRewards(address[], address).selector,
    g -> g.selector == sig:ao.getAllUserRewards(address[], address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetUserRewards(method f, method g)
filtered {
    f -> f.selector == sig:a.getUserRewards(address[], address, address).selector,
    g -> g.selector == sig:ao.getUserRewards(address[], address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetRewardsData(method f, method g)
filtered {
    f -> f.selector == sig:a.getRewardsData(address, address).selector,
    g -> g.selector == sig:ao.getRewardsData(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetAssetIndex(method f, method g)
filtered {
    f -> f.selector == sig:a.getAssetIndex(address, address).selector,
    g -> g.selector == sig:ao.getAssetIndex(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetDistributionEnd(method f, method g)
filtered {
    f -> f.selector == sig:a.getDistributionEnd(address, address).selector,
    g -> g.selector == sig:ao.getDistributionEnd(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetRewardsByAsset(method f, method g)
filtered {
    f -> f.selector == sig:a.getRewardsByAsset(address).selector,
    g -> g.selector == sig:ao.getRewardsByAsset(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetRewardsList(method f, method g)
filtered {
    f -> f.selector == sig:a.getRewardsList().selector,
    g -> g.selector == sig:ao.getRewardsList().selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetUserAssetIndex(method f, method g)
filtered {
    f -> f.selector == sig:a.getUserAssetIndex(address, address, address).selector,
    g -> g.selector == sig:ao.getUserAssetIndex(address, address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetAssetDecimals(method f, method g)
filtered {
    f -> f.selector == sig:a.getAssetDecimals(address).selector,
    g -> g.selector == sig:ao.getAssetDecimals(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetEmissionManager(method f, method g)
filtered {
    f -> f.selector == sig:a.getEmissionManager().selector,
    g -> g.selector == sig:ao.getEmissionManager().selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetDistributionEnd(method f, method g)
filtered {
    f -> f.selector == sig:a.setDistributionEnd(address, address, uint32).selector,
    g -> g.selector == sig:ao.setDistributionEnd(address, address, uint32).selector
} {
    gasOptimizationCorrectness(f, g);
}