//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

import {RewardsController} from "../../aave-v3-origin-liquidation-gas-fixes/src/contracts/rewards/RewardsController.sol";

contract RewardsControllerOptimized is RewardsController {
constructor(address emissionManager) RewardsController(emissionManager) {}
}
