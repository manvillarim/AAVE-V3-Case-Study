import "Structures/GhostRewardsController.spec";

methods {
    function _.scaledTotalSupply() external => ghostScaledTotalSupply[calledContract] expect uint256 ALL;
    function _.getScaledUserBalanceAndSupply(address) external => ghostGetScaledUserBalanceAndSupply(calledContract, calledContract) expect (uint256, uint256) ALL;
    function _.performTransfer(address, address, uint256) external => ghostPerformTransfer(calledContract) expect bool ALL;
    function _.latestAnswer() external => ghostLatestAnswer(calledContract) expect int256 ALL;
    function _.decimals() external => ghostDecimals(calledContract) expect uint8 ALL;
    
    function a.getClaimer(address) external returns (address) envfree;
    function ao.getClaimer(address) external returns (address) envfree;
    
    function a.getRewardOracle(address) external returns (address) envfree;
    function ao.getRewardOracle(address) external returns (address) envfree;
    
    function a.getTransferStrategy(address) external returns (address) envfree;
    function ao.getTransferStrategy(address) external returns (address) envfree;

    function a.configureAssets(RewardsDataTypes.RewardsConfigInput[]) external;
    function ao.configureAssets(RewardsDataTypes.RewardsConfigInput[]) external;
}

definition CouplingInv() returns bool =
    a.EMISSION_MANAGER == ao.EMISSION_MANAGER &&
    
    a.lastInitializedRevision == ao.lastInitializedRevision &&
    a.initializing == ao.initializing &&
    
    (forall address user.
        ghost_a_authorizedClaimers[user] == ghost_ao_authorizedClaimers[user]
    ) &&
    
    (forall address reward.
        ghost_a_transferStrategy[reward] == ghost_ao_transferStrategy[reward]
    ) &&
    
    (forall address reward.
        ghost_a_rewardOracle[reward] == ghost_ao_rewardOracle[reward]
    ) &&
    
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

rule gasOptimizedCorrectnessOfSetTransferStrategy(method f, method g)
filtered {
    f -> f.selector == sig:a.setTransferStrategy(address, address).selector,
    g -> g.selector == sig:ao.setTransferStrategy(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetRewardOracle(method f, method g)
filtered {
    f -> f.selector == sig:a.setRewardOracle(address, address).selector,
    g -> g.selector == sig:ao.setRewardOracle(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfHandleAction(method f, method g)
filtered {
    f -> f.selector == sig:a.handleAction(address, uint256, uint256).selector,
    g -> g.selector == sig:ao.handleAction(address, uint256, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimRewards(method f, method g)
filtered {
    f -> f.selector == sig:a.claimRewards(address[], uint256, address, address).selector,
    g -> g.selector == sig:ao.claimRewards(address[], uint256, address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimRewardsOnBehalf(method f, method g)
filtered {
    f -> f.selector == sig:a.claimRewardsOnBehalf(address[], uint256, address, address, address).selector,
    g -> g.selector == sig:ao.claimRewardsOnBehalf(address[], uint256, address, address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimRewardsToSelf(method f, method g)
filtered {
    f -> f.selector == sig:a.claimRewardsToSelf(address[], uint256, address).selector,
    g -> g.selector == sig:ao.claimRewardsToSelf(address[], uint256, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimAllRewards(method f, method g)
filtered {
    f -> f.selector == sig:a.claimAllRewards(address[], address).selector,
    g -> g.selector == sig:ao.claimAllRewards(address[], address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimAllRewardsOnBehalf(method f, method g)
filtered {
    f -> f.selector == sig:a.claimAllRewardsOnBehalf(address[], address, address).selector,
    g -> g.selector == sig:ao.claimAllRewardsOnBehalf(address[], address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfClaimAllRewardsToSelf(method f, method g)
filtered {
    f -> f.selector == sig:a.claimAllRewardsToSelf(address[]).selector,
    g -> g.selector == sig:ao.claimAllRewardsToSelf(address[]).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfSetClaimer(method f, method g)
filtered {
    f -> f.selector == sig:a.setClaimer(address, address).selector,
    g -> g.selector == sig:ao.setClaimer(address, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetClaimer(method f, method g)
filtered {
    f -> f.selector == sig:a.getClaimer(address).selector,
    g -> g.selector == sig:ao.getClaimer(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetRewardOracle(method f, method g)
filtered {
    f -> f.selector == sig:a.getRewardOracle(address).selector,
    g -> g.selector == sig:ao.getRewardOracle(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetTransferStrategy(method f, method g)
filtered {
    f -> f.selector == sig:a.getTransferStrategy(address).selector,
    g -> g.selector == sig:ao.getTransferStrategy(address).selector
} {
    gasOptimizationCorrectness(f, g);
}