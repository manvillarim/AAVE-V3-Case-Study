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

ghost mapping(address => bool) ghostTransferSuccess {
    init_state axiom forall address token. ghostTransferSuccess[token] == true;
}

ghost mapping(address => bool) ghostTransferFromSuccess {
    init_state axiom forall address token. ghostTransferFromSuccess[token] == true;
}

ghost mapping(uint256 => uint256) ghost_a_gap {
    init_state axiom forall uint256 i. i < 53 => ghost_a_gap[i] == 0;
}

ghost mapping(uint256 => uint256) ghost_ao_gap {
    init_state axiom forall uint256 i. i < 53 => ghost_ao_gap[i] == 0;
}

ghost uint256 ghost_a_nextStreamId {
    init_state axiom ghost_a_nextStreamId == 0;
}

ghost uint256 ghost_ao_nextStreamId {
    init_state axiom ghost_ao_nextStreamId == 0;
}

ghost mapping(uint256 => address) ghost_a_streams_sender {
    init_state axiom forall uint256 streamId. ghost_a_streams_sender[streamId] == 0;
}
ghost mapping(uint256 => address) ghost_a_streams_recipient {
    init_state axiom forall uint256 streamId. ghost_a_streams_recipient[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_a_streams_deposit {
    init_state axiom forall uint256 streamId. ghost_a_streams_deposit[streamId] == 0;
}
ghost mapping(uint256 => address) ghost_a_streams_tokenAddress {
    init_state axiom forall uint256 streamId. ghost_a_streams_tokenAddress[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_a_streams_startTime {
    init_state axiom forall uint256 streamId. ghost_a_streams_startTime[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_a_streams_stopTime {
    init_state axiom forall uint256 streamId. ghost_a_streams_stopTime[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_a_streams_remainingBalance {
    init_state axiom forall uint256 streamId. ghost_a_streams_remainingBalance[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_a_streams_ratePerSecond {
    init_state axiom forall uint256 streamId. ghost_a_streams_ratePerSecond[streamId] == 0;
}
ghost mapping(uint256 => bool) ghost_a_streams_isEntity {
    init_state axiom forall uint256 streamId. ghost_a_streams_isEntity[streamId] == false;
}

ghost mapping(uint256 => address) ghost_ao_streams_sender {
    init_state axiom forall uint256 streamId. ghost_ao_streams_sender[streamId] == 0;
}
ghost mapping(uint256 => address) ghost_ao_streams_recipient {
    init_state axiom forall uint256 streamId. ghost_ao_streams_recipient[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_ao_streams_deposit {
    init_state axiom forall uint256 streamId. ghost_ao_streams_deposit[streamId] == 0;
}
ghost mapping(uint256 => address) ghost_ao_streams_tokenAddress {
    init_state axiom forall uint256 streamId. ghost_ao_streams_tokenAddress[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_ao_streams_startTime {
    init_state axiom forall uint256 streamId. ghost_ao_streams_startTime[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_ao_streams_stopTime {
    init_state axiom forall uint256 streamId. ghost_ao_streams_stopTime[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_ao_streams_remainingBalance {
    init_state axiom forall uint256 streamId. ghost_ao_streams_remainingBalance[streamId] == 0;
}
ghost mapping(uint256 => uint256) ghost_ao_streams_ratePerSecond {
    init_state axiom forall uint256 streamId. ghost_ao_streams_ratePerSecond[streamId] == 0;
}
ghost mapping(uint256 => bool) ghost_ao_streams_isEntity {
    init_state axiom forall uint256 streamId. ghost_ao_streams_isEntity[streamId] == false;
}

ghost mapping(bytes32 => mapping(address => bool)) ghost_a_roles {
    init_state axiom forall bytes32 role. forall address account.
        ghost_a_roles[role][account] == false;
}

ghost mapping(bytes32 => mapping(address => bool)) ghost_ao_roles {
    init_state axiom forall bytes32 role. forall address account.
        ghost_ao_roles[role][account] == false;
}

ghost uint256 ghost_a_reentrancyStatus {
    init_state axiom ghost_a_reentrancyStatus == 1;
}

ghost uint256 ghost_ao_reentrancyStatus {
    init_state axiom ghost_ao_reentrancyStatus == 1;
}

hook Sstore a.______gap[INDEX uint256 i] uint256 newValue {
    ghost_a_gap[i] = newValue;
}

hook Sload uint256 val a.______gap[INDEX uint256 i]  {
    require ghost_a_gap[i] == val;
}

hook Sstore a._nextStreamId uint256 newValue (uint256 oldValue) {
    ghost_a_nextStreamId = newValue;
}

hook Sload uint256 val a._nextStreamId {
    require ghost_a_nextStreamId == val;
}

hook Sstore a._streams[KEY uint256 streamId].sender address newValue (address oldValue) {
    ghost_a_streams_sender[streamId] = newValue;
}

hook Sload address val a._streams[KEY uint256 streamId].sender {
    require ghost_a_streams_sender[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].recipient address newValue (address oldValue) {
    ghost_a_streams_recipient[streamId] = newValue;
}

hook Sload address val a._streams[KEY uint256 streamId].recipient {
    require ghost_a_streams_recipient[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].deposit uint256 newValue (uint256 oldValue) {
    ghost_a_streams_deposit[streamId] = newValue;
}

hook Sload uint256 val a._streams[KEY uint256 streamId].deposit {
    require ghost_a_streams_deposit[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].tokenAddress address newValue (address oldValue) {
    ghost_a_streams_tokenAddress[streamId] = newValue;
}

hook Sload address val a._streams[KEY uint256 streamId].tokenAddress {
    require ghost_a_streams_tokenAddress[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].startTime uint256 newValue (uint256 oldValue) {
    ghost_a_streams_startTime[streamId] = newValue;
}

hook Sload uint256 val a._streams[KEY uint256 streamId].startTime {
    require ghost_a_streams_startTime[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].stopTime uint256 newValue (uint256 oldValue) {
    ghost_a_streams_stopTime[streamId] = newValue;
}

hook Sload uint256 val a._streams[KEY uint256 streamId].stopTime {
    require ghost_a_streams_stopTime[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].remainingBalance uint256 newValue (uint256 oldValue) {
    ghost_a_streams_remainingBalance[streamId] = newValue;
}

hook Sload uint256 val a._streams[KEY uint256 streamId].remainingBalance {
    require ghost_a_streams_remainingBalance[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].ratePerSecond uint256 newValue (uint256 oldValue) {
    ghost_a_streams_ratePerSecond[streamId] = newValue;
}

hook Sload uint256 val a._streams[KEY uint256 streamId].ratePerSecond {
    require ghost_a_streams_ratePerSecond[streamId] == val;
}

hook Sstore a._streams[KEY uint256 streamId].isEntity bool newValue (bool oldValue) {
    ghost_a_streams_isEntity[streamId] = newValue;
}

hook Sload bool val a._streams[KEY uint256 streamId].isEntity {
    require ghost_a_streams_isEntity[streamId] == val;
}

hook Sstore ao.______gap[INDEX uint256 i] uint256 newValue  {
    ghost_ao_gap[i] = newValue;
}

hook Sload uint256 val ao.______gap[INDEX uint256 i]  {
    require ghost_ao_gap[i] == val;
}

hook Sstore ao._nextStreamId uint256 newValue (uint256 oldValue) {
    ghost_ao_nextStreamId = newValue;
}

hook Sload uint256 val ao._nextStreamId {
    require ghost_ao_nextStreamId == val;
}

hook Sstore ao._streams[KEY uint256 streamId].sender address newValue (address oldValue) {
    ghost_ao_streams_sender[streamId] = newValue;
}

hook Sload address val ao._streams[KEY uint256 streamId].sender {
    require ghost_ao_streams_sender[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].recipient address newValue (address oldValue) {
    ghost_ao_streams_recipient[streamId] = newValue;
}

hook Sload address val ao._streams[KEY uint256 streamId].recipient {
    require ghost_ao_streams_recipient[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].deposit uint256 newValue (uint256 oldValue) {
    ghost_ao_streams_deposit[streamId] = newValue;
}

hook Sload uint256 val ao._streams[KEY uint256 streamId].deposit {
    require ghost_ao_streams_deposit[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].tokenAddress address newValue (address oldValue) {
    ghost_ao_streams_tokenAddress[streamId] = newValue;
}

hook Sload address val ao._streams[KEY uint256 streamId].tokenAddress {
    require ghost_ao_streams_tokenAddress[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].startTime uint256 newValue (uint256 oldValue) {
    ghost_ao_streams_startTime[streamId] = newValue;
}

hook Sload uint256 val ao._streams[KEY uint256 streamId].startTime {
    require ghost_ao_streams_startTime[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].stopTime uint256 newValue (uint256 oldValue) {
    ghost_ao_streams_stopTime[streamId] = newValue;
}

hook Sload uint256 val ao._streams[KEY uint256 streamId].stopTime {
    require ghost_ao_streams_stopTime[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].remainingBalance uint256 newValue (uint256 oldValue) {
    ghost_ao_streams_remainingBalance[streamId] = newValue;
}

hook Sload uint256 val ao._streams[KEY uint256 streamId].remainingBalance {
    require ghost_ao_streams_remainingBalance[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].ratePerSecond uint256 newValue (uint256 oldValue) {
    ghost_ao_streams_ratePerSecond[streamId] = newValue;
}

hook Sload uint256 val ao._streams[KEY uint256 streamId].ratePerSecond {
    require ghost_ao_streams_ratePerSecond[streamId] == val;
}

hook Sstore ao._streams[KEY uint256 streamId].isEntity bool newValue (bool oldValue) {
    ghost_ao_streams_isEntity[streamId] = newValue;
}

hook Sload bool val ao._streams[KEY uint256 streamId].isEntity {
    require ghost_ao_streams_isEntity[streamId] == val;
}

definition couplingInv() returns bool =
    ghost_a_nextStreamId == ghost_ao_nextStreamId &&
    
    (forall uint256 i. i < 53 => ghost_a_gap[i] == ghost_ao_gap[i]) &&
    
    (forall uint256 streamId.
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
    
    ghost_a_reentrancyStatus == ghost_ao_reentrancyStatus;

function gasOptimizationCorrectness(method f, method g) {
    env eA;
    env eAo;
    calldataarg args;
    
    require eA.msg.sender == eAo.msg.sender;
    require eA.msg.value == eAo.msg.value;
    require eA.block.timestamp == eAo.block.timestamp;
    require eA.block.number == eAo.block.number;
    
    require couplingInv();
    
    require forall address token. 
        ghostTransferSuccess[token] == ghostTransferSuccess[token];
    require forall address token.
        ghostTransferFromSuccess[token] == ghostTransferFromSuccess[token];
    
    a.f(eA, args);
    ao.g(eAo, args);
    
    assert couplingInv();
}

rule gasOptimizedCorrectnessOfApprove(method f, method g)
filtered {
    f -> f.selector == sig:a.approve(address, address, uint256).selector,
    g -> g.selector == sig:ao.approve(address, address, uint256).selector
} {
    gasOptimizationCorrectness(f, g);
}

rule gasOptimizedCorrectnessOfTransfer(method f, method g)
filtered {
    f -> f.selector == sig:a.transfer(address, address, uint256).selector,
    g -> g.selector == sig:ao.transfer(address, address, uint256).selector
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