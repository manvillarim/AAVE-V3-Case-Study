// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VersionedInitializable} from '../misc/aave-upgradeability/VersionedInitializable.sol';
import {SafeCast} from '../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IScaledBalanceToken} from '../interfaces/IScaledBalanceToken.sol';
import {RewardsDistributor} from './RewardsDistributor.sol';
import {IRewardsController} from './interfaces/IRewardsController.sol';
import {ITransferStrategyBase} from './interfaces/ITransferStrategyBase.sol';
import {RewardsDataTypes} from './libraries/RewardsDataTypes.sol';
import {AggregatorInterface} from '../dependencies/chainlink/AggregatorInterface.sol';

/**
 * @title RewardsController
 * @notice Abstract contract template to build Distributors contracts for ERC20 rewards to protocol participants
 * @author Aave
 **/
contract RewardsController is RewardsDistributor, VersionedInitializable, IRewardsController {
  using SafeCast for uint256;

  uint256 public constant REVISION = 1;

  // RULE 1 - Replace require with custom errors
  error InvalidToAddress();
  error InvalidUserAddress();
  error ClaimerUnauthorized();
  error StrategyCanNotBeZero();
  error StrategyMustBeContract();
  error OracleMustReturnPrice();
  error TransferError();

  mapping(address => address) internal _authorizedClaimers;
  mapping(address => ITransferStrategyBase) internal _transferStrategy;
  mapping(address => AggregatorInterface) internal _rewardOracle;

  modifier onlyAuthorizedClaimers(address claimer, address user) {
    // RULE 1 - Replace require with custom errors
    if (_authorizedClaimers[user] != claimer) revert ClaimerUnauthorized();
    _;
  }

  constructor(address emissionManager) RewardsDistributor(emissionManager) {}

  function initialize(address) external initializer {}

  /// @inheritdoc IRewardsController
  function getClaimer(address user) external view override returns (address) {
    return _authorizedClaimers[user];
  }

  function getRevision() internal pure override returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0000, 1037618708495) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff000f0001, 0) }
    return REVISION;
  }

  /// @inheritdoc IRewardsController
  function getRewardOracle(address reward) external view override returns (address) {
    return address(_rewardOracle[reward]);
  }

  /// @inheritdoc IRewardsController
  function getTransferStrategy(address reward) external view override returns (address) {
    return address(_transferStrategy[reward]);
  }

  /// @inheritdoc IRewardsController
  function configureAssets(
    RewardsDataTypes.RewardsConfigInput[] memory config
  ) external override onlyEmissionManager {
    // RULE 25 - Cache array length in loops
    uint256 configLength = config.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,configLength)}
    // RULE 9  - Avoid explicit zero initialization (i declared without = 0)
    for (uint256 i; i < configLength; ) {
      config[i].totalSupply = IScaledBalanceToken(config[i].asset).scaledTotalSupply();uint256 certora_local19 = config[i].totalSupply;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,certora_local19)}
      _installTransferStrategy(config[i].reward, config[i].transferStrategy);
      _setRewardOracle(config[i].reward, config[i].rewardOracle);
      // RULE 28 - Unchecked arithmetic: i < configLength guarantees no overflow
      unchecked { ++i; }
    }
    _configureAssets(config);
  }

  /// @inheritdoc IRewardsController
  function setTransferStrategy(
    address reward,
    ITransferStrategyBase transferStrategy
  ) external onlyEmissionManager {
    _installTransferStrategy(reward, transferStrategy);
  }

  /// @inheritdoc IRewardsController
  function setRewardOracle(
    address reward,
    AggregatorInterface rewardOracle
  ) external onlyEmissionManager {
    _setRewardOracle(reward, rewardOracle);
  }

  /// @inheritdoc IRewardsController
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external override {
    _updateData(msg.sender, user, userBalance, totalSupply);
  }

  /// @inheritdoc IRewardsController
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external override returns (uint256) {
    // RULE 1 - Replace require with custom errors
    if (to == address(0)) revert InvalidToAddress();
    return _claimRewards(assets, amount, msg.sender, msg.sender, to, reward);
  }

  /// @inheritdoc IRewardsController
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external override onlyAuthorizedClaimers(msg.sender, user) returns (uint256) {
    // RULE 1 - Replace require with custom errors
    if (user == address(0)) revert InvalidUserAddress();
    if (to == address(0)) revert InvalidToAddress();
    return _claimRewards(assets, amount, msg.sender, user, to, reward);
  }

  /// @inheritdoc IRewardsController
  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external override returns (uint256) {
    return _claimRewards(assets, amount, msg.sender, msg.sender, msg.sender, reward);
  }

  /// @inheritdoc IRewardsController
  function claimAllRewards(
    address[] calldata assets,
    address to
  ) external override returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {
    // RULE 1 - Replace require with custom errors
    if (to == address(0)) revert InvalidToAddress();
    (rewardsList, claimedAmounts) = _claimAllRewards(assets, msg.sender, msg.sender, to);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000b,0)}
  }

  /// @inheritdoc IRewardsController
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  )
    external
    override
    onlyAuthorizedClaimers(msg.sender, user)
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts)
  {
    // RULE 1 - Replace require with custom errors
    if (user == address(0)) revert InvalidUserAddress();
    if (to == address(0)) revert InvalidToAddress();
    (rewardsList, claimedAmounts) = _claimAllRewards(assets, msg.sender, user, to);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000c,0)}
  }

  /// @inheritdoc IRewardsController
  function claimAllRewardsToSelf(
    address[] calldata assets
  ) external override returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {
    (rewardsList, claimedAmounts) = _claimAllRewards(assets, msg.sender, msg.sender, msg.sender);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000d,0)}
  }

  /// @inheritdoc IRewardsController
  function setClaimer(address user, address caller) external override onlyEmissionManager {
    _authorizedClaimers[user] = caller;
    emit ClaimerSet(user, caller);
  }

  function _getUserAssetBalances(
    address[] calldata assets,
    address user
  ) internal view override returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100000, 1037618708496) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00103000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00102000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101001, user) }
    // RULE 25 - Cache array length in loops
    uint256 assetsLength = assets.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,assetsLength)}
    userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assetsLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000e,0)}
    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < assetsLength; ) {
      // RULE 24 - Cache array member variable
      address asset = assets[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,asset)}
      userAssetBalances[i].asset = asset;address certora_local20 = userAssetBalances[i].asset;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000014,certora_local20)}
      (userAssetBalances[i].userBalance, userAssetBalances[i].totalSupply) = IScaledBalanceToken(
        asset
      ).getScaledUserBalanceAndSupply(user);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020015,0)}
      // RULE 28 - Unchecked arithmetic: i < assetsLength guarantees no overflow
      unchecked { ++i; }
    }
  }

  function _claimRewards(
    address[] calldata assets,
    uint256 amount,
    address claimer,
    address user,
    address to,
    address reward
  ) internal returns (uint256 totalRewards) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120000, 1037618708498) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00120001, 7) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00123000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00122000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121001, amount) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121002, claimer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121003, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121004, to) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00121005, reward) }
    if (amount != 0) {
      _updateDataMultiple(user, _getUserAssetBalances(assets, user));
      // RULE 25 - Cache array length in loops
      uint256 assetsLength = assets.length;
      // RULE 9  - Avoid explicit zero initialization
      for (uint256 i; i < assetsLength; ) {
        // RULE 24 - Cache array member variable
        address asset = assets[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,asset)}
        totalRewards += _assets[asset].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000018,totalRewards)}

        if (totalRewards <= amount) {
          _assets[asset].rewards[reward].usersData[user].accrued = 0;
        } else {
          uint256 difference = totalRewards - amount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,difference)}
          totalRewards -= difference;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001a,totalRewards)}
          _assets[asset].rewards[reward].usersData[user].accrued = difference.toUint128();
          break;
        }
        // RULE 28 - Unchecked arithmetic: i < assetsLength guarantees no overflow
        unchecked { ++i; }
      }

      if (totalRewards != 0) {
        _transferRewards(to, reward, totalRewards);
        emit RewardsClaimed(user, reward, to, claimer, totalRewards);
      }
    }
  }

  function _claimAllRewards(
    address[] calldata assets,
    address claimer,
    address user,
    address to
  ) internal returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130000, 1037618708499) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00133000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00132000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131001, claimer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131002, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131003, to) }
    // RULE 25 - Cache array length in loops
    uint256 rewardsListLength = _rewardsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,rewardsListLength)}
    uint256 assetsLength = assets.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,assetsLength)}
    rewardsList = new address[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000f,0)}
    claimedAmounts = new uint256[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020010,0)}

    _updateDataMultiple(user, _getUserAssetBalances(assets, user));

    // RULE 9  - Avoid explicit zero initialization
    for (uint256 i; i < assetsLength; ) {
      // RULE 24 - Cache array member variable
      address asset = assets[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,asset)}
      for (uint256 j; j < rewardsListLength; ) {
        if (rewardsList[j] == address(0)) {
          rewardsList[j] = _rewardsList[j];
        }
        uint256 rewardAmount = _assets[asset].rewards[rewardsList[j]].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,rewardAmount)}
        if (rewardAmount != 0) {
          claimedAmounts[j] += rewardAmount;
          _assets[asset].rewards[rewardsList[j]].usersData[user].accrued = 0;
        }
        // RULE 28 - Unchecked arithmetic: j < rewardsListLength guarantees no overflow
        unchecked { ++j; }
      }
      // RULE 28 - Unchecked arithmetic: i < assetsLength guarantees no overflow
      unchecked { ++i; }
    }
    for (uint256 i; i < rewardsListLength; ) {
      _transferRewards(to, rewardsList[i], claimedAmounts[i]);
      emit RewardsClaimed(user, rewardsList[i], to, claimer, claimedAmounts[i]);
      // RULE 28 - Unchecked arithmetic: i < rewardsListLength guarantees no overflow
      unchecked { ++i; }
    }
  }

  function _transferRewards(address to, address reward, uint256 amount) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110000, 1037618708497) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111000, to) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111002, amount) }
    ITransferStrategyBase transferStrategy = _transferStrategy[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010008,0)}
    bool success = transferStrategy.performTransfer(to, reward, amount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000009,success)}
    // RULE 1  - Replace require with custom errors
    // RULE 17 - Write values directly: success == true → success
    if (!success) revert TransferError();
  }

  function _isContract(address account) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140000, 1037618708500) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141000, account) }
    uint256 size;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000a,size)}
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function _installTransferStrategy(
    address reward,
    ITransferStrategyBase transferStrategy
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150000, 1037618708501) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151000, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151001, transferStrategy) }
    // RULE 1 - Replace require with custom errors
    if (address(transferStrategy) == address(0)) revert StrategyCanNotBeZero();
    // RULE 17 - Write values directly: == true → bare boolean
    if (!_isContract(address(transferStrategy))) revert StrategyMustBeContract();
    _transferStrategy[reward] = transferStrategy;
    emit TransferStrategyInstalled(reward, address(transferStrategy));
  }

  function _setRewardOracle(address reward, AggregatorInterface rewardOracle) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160000, 1037618708502) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161000, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161001, rewardOracle) }
    // RULE 1 - Replace require with custom errors
    if (rewardOracle.latestAnswer() <= 0) revert OracleMustReturnPrice();
    _rewardOracle[reward] = rewardOracle;
    emit RewardOracleUpdated(reward, address(rewardOracle));
  }
}