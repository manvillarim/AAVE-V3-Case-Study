// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {RewardsController} from '../../src/contracts/rewards/RewardsController.sol';
import {RewardsDataTypes} from '../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {IScaledBalanceToken} from '../../src/contracts/interfaces/IScaledBalanceToken.sol';
import {ITransferStrategyBase} from '../../src/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

contract MockTransferStrategy is ITransferStrategyBase {
    function performTransfer(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        return true;
    }
    
    function getIncentivesController() external pure override returns (address) {
        return address(0);
    }
    
    function getRewardsAdmin() external pure override returns (address) {
        return address(0);
    }
    
    function emergencyWithdrawal(
        address,
        address,
        uint256
    ) external pure override {}
}

contract MockAggregator is AggregatorInterface {
    function latestAnswer() external pure override returns (int256) {
        return 1e8;
    }
    
    function latestTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }
    
    function latestRound() external pure override returns (uint256) {
        return 1;
    }
    
    function getAnswer(uint256) external pure override returns (int256) {
        return 1e8;
    }
    
    function getTimestamp(uint256) external view override returns (uint256) {
        return block.timestamp;
    }
    
    function decimals() external pure returns (uint8) {
        return 8;
    }
    
    function description() external pure returns (string memory) {
        return "Mock Aggregator";
    }
    
    function version() external pure returns (uint256) {
        return 1;
    }
    
    function getRoundData(uint80)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, 1e8, block.timestamp, block.timestamp, 1);
    }
    
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, 1e8, block.timestamp, block.timestamp, 1);
    }
}

contract MockScaledBalanceToken is IScaledBalanceToken, IERC20 {
    uint256 private _scaledTotalSupply = 10000e18;
    
    function scaledTotalSupply() external view override returns (uint256) {
        return _scaledTotalSupply;
    }
    
    function scaledBalanceOf(address) external pure override returns (uint256) {
        return 1000e18;
    }
    
    function getScaledUserBalanceAndSupply(address) external view override returns (uint256, uint256) {
        return (1000e18, _scaledTotalSupply);
    }
    
    function decimals() external pure returns (uint8) {
        return 18;
    }
    
    function totalSupply() external view override returns (uint256) {
        return _scaledTotalSupply;
    }
    
    function balanceOf(address) external pure override returns (uint256) {
        return 1000e18;
    }
    
    function transfer(address, uint256) external pure override returns (bool) {
        return true;
    }
    
    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }
    
    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }
    
    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return true;
    }
    
    function name() external pure returns (string memory) {
        return "Mock Token";
    }

    function symbol() external pure returns (string memory) {
        return "MOCK";
    }
    
    function mint(address, address, uint256, uint256) external pure returns (bool) {
        return true;
    }

    function burn(address, address, uint256, uint256) external pure returns (bool) {
        return true;
    }

    function mintToTreasury(uint256, uint256) external pure {}
    
    function getPreviousIndex(address) external pure returns (uint256) {
        return 0;
    }
}

/// forge-config: default.isolate = true
contract RewardsController_gas_Tests is Test {
    RewardsController public controller;
    MockScaledBalanceToken public asset1;
    MockScaledBalanceToken public asset2;
    MockScaledBalanceToken public asset3;
    MockTransferStrategy public transferStrategy;
    MockAggregator public oracle;
    
    address emissionManager = makeAddr('emissionManager');
    address reward1 = makeAddr('reward1');
    address reward2 = makeAddr('reward2');
    address reward3 = makeAddr('reward3');
    address user = makeAddr('user');
    address claimer = makeAddr('claimer');
    address recipient = makeAddr('recipient');
    
    function setUp() public {
        controller = new RewardsController(emissionManager);
        controller.initialize(address(0));
        
        asset1 = new MockScaledBalanceToken();
        asset2 = new MockScaledBalanceToken();
        asset3 = new MockScaledBalanceToken();
        
        transferStrategy = new MockTransferStrategy();
        oracle = new MockAggregator();
    }
    
    function test_getClaimer() external {
        _setupSingleAssetReward();
        
        controller.getClaimer(user);
        vm.snapshotGasLastCall('RewardsController', 'getClaimer');
    }
    
    function test_getRewardOracle() external {
        _setupSingleAssetReward();
        
        controller.getRewardOracle(reward1);
        vm.snapshotGasLastCall('RewardsController', 'getRewardOracle');
    }
    
    function test_getTransferStrategy() external {
        _setupSingleAssetReward();
        
        controller.getTransferStrategy(reward1);
        vm.snapshotGasLastCall('RewardsController', 'getTransferStrategy');
    }
    
    function test_configureAssets_one() external {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](1);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        
        vm.prank(emissionManager);
        controller.configureAssets(config);
        vm.snapshotGasLastCall('RewardsController', 'configureAssets_one');
    }
    
    function test_configureAssets_three() external {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](3);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        config[1] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 150,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset2),
            reward: reward2,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        config[2] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 200,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset3),
            reward: reward3,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        
        vm.prank(emissionManager);
        controller.configureAssets(config);
        vm.snapshotGasLastCall('RewardsController', 'configureAssets_three');
    }
    
    function test_setTransferStrategy() external {
        _setupSingleAssetReward();
        
        MockTransferStrategy newStrategy = new MockTransferStrategy();
        
        vm.prank(emissionManager);
        controller.setTransferStrategy(reward1, newStrategy);
        vm.snapshotGasLastCall('RewardsController', 'setTransferStrategy');
    }
    
    function test_setRewardOracle() external {
        _setupSingleAssetReward();
        
        MockAggregator newOracle = new MockAggregator();
        
        vm.prank(emissionManager);
        controller.setRewardOracle(reward1, newOracle);
        vm.snapshotGasLastCall('RewardsController', 'setRewardOracle');
    }
    
    function test_handleAction() external {
        _setupSingleAssetReward();
        
        vm.prank(address(asset1));
        controller.handleAction(user, 10000e18, 1000e18);
        vm.snapshotGasLastCall('RewardsController', 'handleAction');
    }
    
    function test_claimRewards_one() external {
        _setupSingleAssetReward();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(user);
        controller.claimRewards(assets, type(uint256).max, recipient, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewards_one');
    }
    
    function test_claimRewards_three() external {
        _setupThreeAssets();
        _accrueRewardsMultiple();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(user);
        controller.claimRewards(assets, type(uint256).max, recipient, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewards_three');
    }
    
    function test_claimRewardsOnBehalf_one() external {
        _setupSingleAssetReward();
        _setClaimer();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(claimer);
        controller.claimRewardsOnBehalf(assets, type(uint256).max, user, recipient, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewardsOnBehalf_one');
    }
    
    function test_claimRewardsOnBehalf_three() external {
        _setupThreeAssets();
        _setClaimer();
        _accrueRewardsMultiple();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(claimer);
        controller.claimRewardsOnBehalf(assets, type(uint256).max, user, recipient, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewardsOnBehalf_three');
    }
    
    function test_claimRewardsToSelf_one() external {
        _setupSingleAssetReward();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(user);
        controller.claimRewardsToSelf(assets, type(uint256).max, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewardsToSelf_one');
    }
    
    function test_claimRewardsToSelf_three() external {
        _setupThreeAssets();
        _accrueRewardsMultiple();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(user);
        controller.claimRewardsToSelf(assets, type(uint256).max, reward1);
        vm.snapshotGasLastCall('RewardsController', 'claimRewardsToSelf_three');
    }
    
    function test_claimAllRewards_one() external {
        _setupSingleAssetReward();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(user);
        controller.claimAllRewards(assets, recipient);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewards_one');
    }
    
    function test_claimAllRewards_3x3() external {
        _setupThreeAssetsThreeRewards();
        _accrueRewards3x3();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(user);
        controller.claimAllRewards(assets, recipient);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewards_3x3');
    }
    
    function test_claimAllRewardsOnBehalf_one() external {
        _setupSingleAssetReward();
        _setClaimer();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(claimer);
        controller.claimAllRewardsOnBehalf(assets, user, recipient);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewardsOnBehalf_one');
    }
    
    function test_claimAllRewardsOnBehalf_3x3() external {
        _setupThreeAssetsThreeRewards();
        _setClaimer();
        _accrueRewards3x3();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(claimer);
        controller.claimAllRewardsOnBehalf(assets, user, recipient);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewardsOnBehalf_3x3');
    }
    
    function test_claimAllRewardsToSelf_one() external {
        _setupSingleAssetReward();
        _accrueRewards();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        vm.prank(user);
        controller.claimAllRewardsToSelf(assets);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewardsToSelf_one');
    }
    
    function test_claimAllRewardsToSelf_3x3() external {
        _setupThreeAssetsThreeRewards();
        _accrueRewards3x3();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        vm.prank(user);
        controller.claimAllRewardsToSelf(assets);
        vm.snapshotGasLastCall('RewardsController', 'claimAllRewardsToSelf_3x3');
    }
    
    function test_setClaimer() external {
        vm.prank(emissionManager);
        controller.setClaimer(user, claimer);
        vm.snapshotGasLastCall('RewardsController', 'setClaimer');
    }
    
    // Helper functions
    
    function _setupSingleAssetReward() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](1);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        
        vm.prank(emissionManager);
        controller.configureAssets(config);
    }
    
    function _setupThreeAssets() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](3);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        config[1] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset2),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        config[2] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 0,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset3),
            reward: reward1,
            transferStrategy: transferStrategy,
            rewardOracle: oracle
        });
        
        vm.prank(emissionManager);
        controller.configureAssets(config);
    }
    
    function _setupThreeAssetsThreeRewards() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](9);
        
        uint256 index;
        address[3] memory assets = [address(asset1), address(asset2), address(asset3)];
        address[3] memory rewards = [reward1, reward2, reward3];
        
        for (uint256 i; i < 3; ++i) {
            for (uint256 j; j < 3; ++j) {
                config[index++] = RewardsDataTypes.RewardsConfigInput({
                    emissionPerSecond: 100,
                    totalSupply: 0,
                    distributionEnd: uint32(block.timestamp + 30 days),
                    asset: assets[i],
                    reward: rewards[j],
                    transferStrategy: transferStrategy,
                    rewardOracle: oracle
                });
            }
        }
        
        vm.prank(emissionManager);
        controller.configureAssets(config);
    }
    
    function _accrueRewards() internal {
        vm.warp(block.timestamp + 1 days);
        vm.prank(address(asset1));
        controller.handleAction(user, 10000e18, 1000e18);
    }
    
    function _accrueRewardsMultiple() internal {
        vm.warp(block.timestamp + 1 days);
        
        vm.prank(address(asset1));
        controller.handleAction(user, 10000e18, 1000e18);
        
        vm.prank(address(asset2));
        controller.handleAction(user, 10000e18, 1000e18);
        
        vm.prank(address(asset3));
        controller.handleAction(user, 10000e18, 1000e18);
    }
    
    function _accrueRewards3x3() internal {
        vm.warp(block.timestamp + 1 days);
        
        address[3] memory assets = [address(asset1), address(asset2), address(asset3)];
        
        for (uint256 i; i < 3; ++i) {
            vm.prank(assets[i]);
            controller.handleAction(user, 10000e18, 1000e18);
        }
    }
    
    function _setClaimer() internal {
        vm.prank(emissionManager);
        controller.setClaimer(user, claimer);
    }
}
