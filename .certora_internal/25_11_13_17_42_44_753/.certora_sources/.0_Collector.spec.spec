import "Structures/GhostCollector.spec";

using CollectorOriginal as a;
using CollectorOptimized as ao;

methods {
    function _.approve(address, uint256) external => ALWAYS(true);
    
    function _.transfer(address, uint256) external => ghostTransferSuccess[calledContract] expect bool;
    
    function _.transferFrom(address, address, uint256) external => ghostTransferFromSuccess[calledContract] expect bool ALL;
    
    function _.safeTransfer(address, uint256) external => NONDET ALL;
    
    function _.forceApprove(address, uint256) external => NONDET ALL;
    
    function _.call(bytes) external => NONDET ALL;
    
    function a.isFundsAdmin(address) external returns (bool) envfree;
    function ao.isFundsAdmin(address) external returns (bool) envfree;
    
    function a.getNextStreamId() external returns (uint256) envfree;
    function ao.getNextStreamId() external returns (uint256) envfree;
    
    function a.hasRole(bytes32, address) external returns (bool) envfree;
    function ao.hasRole(bytes32, address) external returns (bool) envfree;
}

definition couplingInv() returns bool =
    ghost_a_nextStreamId == ghost_ao_nextStreamId &&
    
    (forall uint256 i. i < 53 => ghost_a_gap[i] == ghost_ao_gap[i]) &&
    
    (forall uint256 streamId.
        ghost_a_streams_sender[streamId] == ghost_ao_streams_sender[streamId] && 
        ghost_a_streams_recipient[streamId] == ghost_ao_streams_recipient[streamId] &&
        ghost_a_streams_deposit[streamId] == ghost_ao_streams_deposit[streamId] &&
        ghost_a_streams_tokenAddress[streamId] == ghost_ao_streams_tokenAddress[streamId] &&
        ghost_a_streams_startTime[streamId] == ghost_ao_streams_startTime[streamId] &&
        ghost_a_streams_stopTime[streamId] == ghost_ao_streams_stopTime[streamId] &&
        ghost_a_streams_remainingBalance[streamId] == ghost_ao_streams_remainingBalance[streamId] &&
        ghost_a_streams_ratePerSecond[streamId] == ghost_ao_streams_ratePerSecond[streamId] &&
        ghost_a_streams_isEntity[streamId] == ghost_ao_streams_isEntity[streamId]
    ) &&
    
    (forall bytes32 role. forall address account.
        ghost_a_roles[role][account] == ghost_ao_roles[role][account]
    ) &&
    
    (forall bytes32 role.
        ghost_a_roleAdmin[role] == ghost_ao_roleAdmin[role]
    ) &&
    
    ghost_a_reentrancyStatus == ghost_ao_reentrancyStatus;

function gasOptimizationCorrectness(method f, method g) {
    env eA;
    env eAo;
    calldataarg args;
    
    require eA == eAo && couplingInv();
    require forall address token. 
        ghostTransferSuccess[token] == ghostTransferSuccess[token];
    require forall address token.
        ghostTransferFromSuccess[token] == ghostTransferFromSuccess[token];

    a.f@withrevert(eA, args);
    bool a_reverted = lastReverted;

    ao.g@withrevert(eAo, args);
    bool ao_reverted = lastReverted;

    assert a_reverted == ao_reverted;
    assert couplingInv();
}

rule gasOptimizedCorrectnessOfApprove(method f, method g)
filtered {
    f -> f.selector == sig:a.approve(address, address, uint256).selector,
    g -> g.selector == sig:ao.approve(address, address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCreateStream(method f, method g)
filtered {
    f -> f.selector == sig:a.createStream(address, uint256, address, uint256, uint256).selector,
    g -> g.selector == sig:ao.createStream(address, uint256, address, uint256, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfWithdrawFromStream(method f, method g)
filtered {
    f -> f.selector == sig:a.withdrawFromStream(uint256, uint256).selector,
    g -> g.selector == sig:ao.withdrawFromStream(uint256, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfCancelStream(method f, method g)
filtered {
    f -> f.selector == sig:a.cancelStream(uint256).selector,
    g -> g.selector == sig:ao.cancelStream(uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfDeltaOf(method f, method g)
filtered {
    f -> f.selector == sig:a.deltaOf(uint256).selector,
    g -> g.selector == sig:ao.deltaOf(uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfBalanceOf(method f, method g)
filtered {
    f -> f.selector == sig:a.balanceOf(uint256, address).selector,
    g -> g.selector == sig:ao.balanceOf(uint256, address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfIsFundsAdmin(method f, method g)
filtered {
    f -> f.selector == sig:a.isFundsAdmin(address).selector,
    g -> g.selector == sig:ao.isFundsAdmin(address).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfGetNextStreamId(method f, method g)
filtered {
    f -> f.selector == sig:a.getNextStreamId().selector,
    g -> g.selector == sig:ao.getNextStreamId().selector
} {
    gasOptimizationCorrectness(f, g);
}