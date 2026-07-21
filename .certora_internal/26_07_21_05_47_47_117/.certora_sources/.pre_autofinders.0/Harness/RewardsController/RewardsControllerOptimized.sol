//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

import {RewardsController} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/rewards/RewardsController.sol";

contract RewardsControllerOptimized is RewardsController {
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
}
