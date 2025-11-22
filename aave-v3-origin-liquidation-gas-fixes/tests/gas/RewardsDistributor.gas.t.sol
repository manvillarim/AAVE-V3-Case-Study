// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import {RewardsDistributor} from '../../src/contracts/rewards/RewardsDistributor.sol';
import {RewardsDataTypes} from '../../src/contracts/rewards/libraries/RewardsDataTypes.sol';
import {IScaledBalanceToken} from '../../src/contracts/interfaces/IScaledBalanceToken.sol';
import {ITransferStrategyBase} from '../../src/contracts/rewards/interfaces/ITransferStrategyBase.sol';
import {AggregatorInterface} from '../../src/contracts/dependencies/chainlink/AggregatorInterface.sol';
import {IERC20} from '../../src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';

contract MockRewardsDistributor is RewardsDistributor {
    constructor(address emissionManager) RewardsDistributor(emissionManager) {}
    
    function _getUserAssetBalances(
        address[] calldata assets,
        address user
    ) internal pure override returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances) {
        userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assets.length);
        user;
        for (uint256 i; i < assets.length; ++i) {
            userAssetBalances[i] = RewardsDataTypes.UserAssetBalance({
                asset: assets[i],
                userBalance: 1000e18,
                totalSupply: 10000e18
            });
        }
    }
    
    function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external {
        _configureAssets(config);
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
function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
) external pure returns (bool) {
    caller;
    onBehalfOf;
    amount;
    index;
    return true;
}

function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
) external pure returns (bool) {
        from;
    receiverOfUnderlying;
    amount;
    index;
    return true;
}

function mintToTreasury(uint256 amount, uint256 index) external pure {}
function getPreviousIndex(address user) external pure returns (uint256) {
    user;
    return 0;
}
}

/// forge-config: default.isolate = true
contract RewardsDistributor_gas_Tests is Test {
    MockRewardsDistributor public distributor;
    MockScaledBalanceToken public asset1;
    MockScaledBalanceToken public asset2;
    MockScaledBalanceToken public asset3;
    
    address emissionManager = makeAddr('emissionManager');
    address reward1 = makeAddr('reward1');
    address reward2 = makeAddr('reward2');
    address reward3 = makeAddr('reward3');
    address user = makeAddr('user');
    
    function setUp() public {
        distributor = new MockRewardsDistributor(emissionManager);
        asset1 = new MockScaledBalanceToken();
        asset2 = new MockScaledBalanceToken();
        asset3 = new MockScaledBalanceToken();
    }
    
    function test_getRewardsData() external {
        distributor.getRewardsData(address(asset1), reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getRewardsData');
    }
    
    function test_getAssetIndex() external {
        _setupSingleAssetReward();
        
        distributor.getAssetIndex(address(asset1), reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getAssetIndex');
    }
    
    function test_getDistributionEnd() external {
        _setupSingleAssetReward();
        
        distributor.getDistributionEnd(address(asset1), reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getDistributionEnd');
    }
    
    function test_getRewardsByAsset() external {
        _setupSingleAssetReward();
        
        distributor.getRewardsByAsset(address(asset1));
        vm.snapshotGasLastCall('RewardsDistributor', 'getRewardsByAsset_one');
    }
    
    function test_getRewardsByAsset_threeRewards() external {
        _setupAssetWithThreeRewards();
        
        distributor.getRewardsByAsset(address(asset1));
        vm.snapshotGasLastCall('RewardsDistributor', 'getRewardsByAsset_three');
    }
    
    function test_getRewardsList() external {
        _setupSingleAssetReward();
        
        distributor.getRewardsList();
        vm.snapshotGasLastCall('RewardsDistributor', 'getRewardsList_one');
    }
    
    function test_getRewardsList_threeRewards() external {
        _setupAssetWithThreeRewards();
        
        distributor.getRewardsList();
        vm.snapshotGasLastCall('RewardsDistributor', 'getRewardsList_three');
    }
    
    function test_getUserAssetIndex() external {
        _setupSingleAssetReward();
        
        distributor.getUserAssetIndex(user, address(asset1), reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getUserAssetIndex');
    }
    
    function test_getUserAccruedRewards() external {
        _setupSingleAssetReward();
        
        distributor.getUserAccruedRewards(user, reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getUserAccruedRewards_one');
    }
    
    function test_getUserAccruedRewards_threeAssets() external {
        _setupThreeAssets();
        
        distributor.getUserAccruedRewards(user, reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getUserAccruedRewards_three');
    }
    
    function test_getUserRewards() external {
        _setupSingleAssetReward();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        distributor.getUserRewards(assets, user, reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getUserRewards_one');
    }
    
    function test_getUserRewards_threeAssets() external {
        _setupThreeAssets();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        distributor.getUserRewards(assets, user, reward1);
        vm.snapshotGasLastCall('RewardsDistributor', 'getUserRewards_three');
    }
    
    function test_getAllUserRewards() external {
        _setupSingleAssetReward();
        
        address[] memory assets = new address[](1);
        assets[0] = address(asset1);
        
        distributor.getAllUserRewards(assets, user);
        vm.snapshotGasLastCall('RewardsDistributor', 'getAllUserRewards_one');
    }
    
    function test_getAllUserRewards_threeAssetsThreeRewards() external {
        _setupThreeAssetsThreeRewards();
        
        address[] memory assets = new address[](3);
        assets[0] = address(asset1);
        assets[1] = address(asset2);
        assets[2] = address(asset3);
        
        distributor.getAllUserRewards(assets, user);
        vm.snapshotGasLastCall('RewardsDistributor', 'getAllUserRewards_3x3');
    }
    
    function test_setDistributionEnd() external {
        _setupSingleAssetReward();
        
        vm.prank(emissionManager);
        distributor.setDistributionEnd(address(asset1), reward1, uint32(block.timestamp + 365 days));
        vm.snapshotGasLastCall('RewardsDistributor', 'setDistributionEnd');
    }
    
    function test_setEmissionPerSecond() external {
        _setupSingleAssetReward();
        
        address[] memory rewards = new address[](1);
        rewards[0] = reward1;
        uint88[] memory emissions = new uint88[](1);
        emissions[0] = 200;
        
        vm.prank(emissionManager);
        distributor.setEmissionPerSecond(address(asset1), rewards, emissions);
        vm.snapshotGasLastCall('RewardsDistributor', 'setEmissionPerSecond_one');
    }
    
    function test_setEmissionPerSecond_threeRewards() external {
        _setupAssetWithThreeRewards();
        
        address[] memory rewards = new address[](3);
        rewards[0] = reward1;
        rewards[1] = reward2;
        rewards[2] = reward3;
        uint88[] memory emissions = new uint88[](3);
        emissions[0] = 200;
        emissions[1] = 300;
        emissions[2] = 400;
        
        vm.prank(emissionManager);
        distributor.setEmissionPerSecond(address(asset1), rewards, emissions);
        vm.snapshotGasLastCall('RewardsDistributor', 'setEmissionPerSecond_three');
    }
    
    function test_getAssetDecimals() external {
        _setupSingleAssetReward();
        
        distributor.getAssetDecimals(address(asset1));
        vm.snapshotGasLastCall('RewardsDistributor', 'getAssetDecimals');
    }
    
    function test_getEmissionManager() external {
        distributor.getEmissionManager();
        vm.snapshotGasLastCall('RewardsDistributor', 'getEmissionManager');
    }
    
    function _setupSingleAssetReward() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](1);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        
        vm.prank(emissionManager);
        distributor.configureAssets(config);
    }
    
    function _setupAssetWithThreeRewards() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](3);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        config[1] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 150,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward2,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        config[2] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 200,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward3,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        
        vm.prank(emissionManager);
        distributor.configureAssets(config);
    }
    
    function _setupThreeAssets() internal {
        RewardsDataTypes.RewardsConfigInput[] memory config = new RewardsDataTypes.RewardsConfigInput[](3);
        config[0] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset1),
            reward: reward1,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        config[1] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset2),
            reward: reward1,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        config[2] = RewardsDataTypes.RewardsConfigInput({
            emissionPerSecond: 100,
            totalSupply: 10000e18,
            distributionEnd: uint32(block.timestamp + 30 days),
            asset: address(asset3),
            reward: reward1,
            transferStrategy: ITransferStrategyBase(address(1)),
            rewardOracle: AggregatorInterface(address(1))
        });
        
        vm.prank(emissionManager);
        distributor.configureAssets(config);
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
                    totalSupply: 10000e18,
                    distributionEnd: uint32(block.timestamp + 30 days),
                    asset: assets[i],
                    reward: rewards[j],
                    transferStrategy: ITransferStrategyBase(address(1)),
                    rewardOracle: AggregatorInterface(address(1))
                });
            }
        }
        
        vm.prank(emissionManager);
        distributor.configureAssets(config);
    }
}