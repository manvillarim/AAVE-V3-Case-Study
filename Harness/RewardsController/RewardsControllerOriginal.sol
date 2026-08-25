//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

import {RewardsController} from "aave-v3-origin-instr/src/contracts/rewards/RewardsController.sol";

contract RewardsControllerOriginal is RewardsController {
constructor(address emissionManager) RewardsController(emissionManager) {}

    uint256 public lastClaimReturn;
    address[] public lastClaimAllList;
    uint256[] public lastClaimAllAmounts;

    function claimRewards_instr(address[] calldata assets, uint256 amount, address to, address reward) external returns (uint256) {
        require(to != address(0), 'INVALID_TO_ADDRESS');
        uint256 r = _claimRewards(assets, amount, msg.sender, msg.sender, to, reward);
        lastClaimReturn = r;
        return r;
    }

    function claimRewardsOnBehalf_instr(address[] calldata assets, uint256 amount, address user, address to, address reward) external onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
        require(user != address(0), 'INVALID_USER_ADDRESS');
        require(to != address(0), 'INVALID_TO_ADDRESS');
        uint256 r = _claimRewards(assets, amount, msg.sender, user, to, reward);
        lastClaimReturn = r;
        return r;
    }

    function claimRewardsToSelf_instr(address[] calldata assets, uint256 amount, address reward) external returns (uint256) {
        uint256 r = _claimRewards(assets, amount, msg.sender, msg.sender, msg.sender, reward);
        lastClaimReturn = r;
        return r;
    }

    function claimAllRewards_instr(address[] calldata assets, address to) external returns (address[] memory, uint256[] memory) {
        require(to != address(0), 'INVALID_TO_ADDRESS');
        (address[] memory rl, uint256[] memory ca) = _claimAllRewards(assets, msg.sender, msg.sender, to);
        lastClaimAllList = rl;
        lastClaimAllAmounts = ca;
        return (rl, ca);
    }

    function claimAllRewardsOnBehalf_instr(address[] calldata assets, address user, address to) external onlyAuthorizedClaimers(msg.sender, user) returns (address[] memory, uint256[] memory) {
        require(user != address(0), 'INVALID_USER_ADDRESS');
        require(to != address(0), 'INVALID_TO_ADDRESS');
        (address[] memory rl, uint256[] memory ca) = _claimAllRewards(assets, msg.sender, user, to);
        lastClaimAllList = rl;
        lastClaimAllAmounts = ca;
        return (rl, ca);
    }

    function claimAllRewardsToSelf_instr(address[] calldata assets) external returns (address[] memory, uint256[] memory) {
        (address[] memory rl, uint256[] memory ca) = _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);
        lastClaimAllList = rl;
        lastClaimAllAmounts = ca;
        return (rl, ca);
    }

    uint256 public emitCount;
    bytes32 public emitDigest;

    address public lastAcuAsset;
    address public lastAcuReward;
    uint256 public lastAcuOldEmission;
    uint256 public lastAcuNewEmission;
    uint256 public lastAcuOldDistributionEnd;
    uint256 public lastAcuNewDistributionEnd;
    uint256 public lastAcuAssetIndex;

    address public lastAccruedAsset;
    address public lastAccruedReward;
    address public lastAccruedUser;
    uint256 public lastAccruedAssetIndex;
    uint256 public lastAccruedUserIndex;
    uint256 public lastAccruedAmount;

    function _recordAssetConfigUpdated(
        address asset,
        address reward,
        uint256 oldEmission,
        uint256 newEmission,
        uint256 oldDistributionEnd,
        uint256 newDistributionEnd,
        uint256 assetIndex
    ) internal override {
        lastAcuAsset = asset;
        lastAcuReward = reward;
        lastAcuOldEmission = oldEmission;
        lastAcuNewEmission = newEmission;
        lastAcuOldDistributionEnd = oldDistributionEnd;
        lastAcuNewDistributionEnd = newDistributionEnd;
        lastAcuAssetIndex = assetIndex;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "AssetConfigUpdated",
                asset,
                reward,
                oldEmission,
                newEmission,
                oldDistributionEnd,
                newDistributionEnd,
                assetIndex
            )
        );
    }

    function _recordAccrued(
        address asset,
        address reward,
        address user,
        uint256 assetIndex,
        uint256 userIndex,
        uint256 rewardsAccrued
    ) internal override {
        lastAccruedAsset = asset;
        lastAccruedReward = reward;
        lastAccruedUser = user;
        lastAccruedAssetIndex = assetIndex;
        lastAccruedUserIndex = userIndex;
        lastAccruedAmount = rewardsAccrued;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(
                emitDigest,
                "Accrued",
                asset,
                reward,
                user,
                assetIndex,
                userIndex,
                rewardsAccrued
            )
        );
    }

    address public lastClaimerSetUser;
    address public lastClaimerSetClaimer;

    address public lastRcUser;
    address public lastRcReward;
    address public lastRcTo;
    address public lastRcClaimer;
    uint256 public lastRcAmount;

    address public lastTsiReward;
    address public lastTsiStrategy;

    address public lastRouReward;
    address public lastRouOracle;

    function _recordClaimerSet(address user, address claimer) internal override {
        lastClaimerSetUser = user;
        lastClaimerSetClaimer = claimer;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(abi.encode(emitDigest, "ClaimerSet", user, claimer));
    }

    function _recordRewardsClaimed(
        address user,
        address reward,
        address to,
        address claimer,
        uint256 amount
    ) internal override {
        lastRcUser = user;
        lastRcReward = reward;
        lastRcTo = to;
        lastRcClaimer = claimer;
        lastRcAmount = amount;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "RewardsClaimed", user, reward, to, claimer, amount)
        );
    }

    function _recordTransferStrategyInstalled(
        address reward,
        address transferStrategy
    ) internal override {
        lastTsiReward = reward;
        lastTsiStrategy = transferStrategy;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "TransferStrategyInstalled", reward, transferStrategy)
        );
    }

    function _recordRewardOracleUpdated(
        address reward,
        address rewardOracle
    ) internal override {
        lastRouReward = reward;
        lastRouOracle = rewardOracle;
        unchecked {
            emitCount = emitCount + 1;
        }
        emitDigest = keccak256(
            abi.encode(emitDigest, "RewardOracleUpdated", reward, rewardOracle)
        );
    }
}
