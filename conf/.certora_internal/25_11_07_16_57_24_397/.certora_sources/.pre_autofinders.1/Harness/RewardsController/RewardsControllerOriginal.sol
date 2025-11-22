//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

import {RewardsController} from "../../aave-v3-origin/src/contracts/rewards/RewardsController.sol";

contract RewardsControllerOriginal is RewardsController {
constructor(address emissionManager) RewardsController(emissionManager) {}
}
