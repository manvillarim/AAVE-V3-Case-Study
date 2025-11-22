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

  // Optimization 1: Replace require with custom errors
  error ClaimerUnauthorized();
  error InvalidToAddress();
  error InvalidUserAddress();
  error TransferError();
  error StrategyCannotBeZero();
  error StrategyMustBeContract();
  error OracleMustReturnPrice();

  // This mapping allows whitelisted addresses to claim on behalf of others
  // useful for contracts that hold tokens to be rewarded but don't have any native logic to claim Liquidity Mining rewards
  mapping(address => address) internal _authorizedClaimers;

  // reward => transfer strategy implementation contract
  // The TransferStrategy contract abstracts the logic regarding
  // the source of the reward and how to transfer it to the user.
  mapping(address => ITransferStrategyBase) internal _transferStrategy;

  // This mapping contains the price oracle per reward.
  // A price oracle is enforced for integrators to be able to show incentives at
  // the current Aave UI without the need to setup an external price registry
  // At the moment of reward configuration, the Incentives Controller performs
  // a check to see if the provided reward oracle contains `latestAnswer`.
  mapping(address => AggregatorInterface) internal _rewardOracle;

  modifier onlyAuthorizedClaimers(address claimer, address user) {
    // Optimization 1: Custom error
    if (_authorizedClaimers[user] != claimer) revert ClaimerUnauthorized();
    _;
  }

  constructor(address emissionManager) RewardsDistributor(emissionManager) {}

  /**
   * @dev Initialize for RewardsController
   * @dev It expects an address as argument since its initialized via PoolAddressesProvider._updateImpl()
   **/
  function initialize(address) external initializer {}

  /// @inheritdoc IRewardsController
  function getClaimer(address user) external view override returns (address) {
    return _authorizedClaimers[user];
  }

  /**
   * @dev Returns the revision of the implementation contract
   * @return uint256, current revision version
   */
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
  // Optimization 4: Use calldata instead of memory for function parameters
  function configureAssets(
    RewardsDataTypes.RewardsConfigInput[] memory config
  ) external override onlyEmissionManager {
    // Optimization 2: Cache array length in loops
    uint256 configLength = config.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,configLength)}
    // Optimization 3: Use efficient loop increment (++i instead of i++)
    // Optimization 11: Use unchecked arithmetic for validated operations
    for (uint256 i; i < configLength;) {
      // Get the current Scaled Total Supply of AToken or Debt token
      config[i].totalSupply = IScaledBalanceToken(config[i].asset).scaledTotalSupply();uint256 certora_local18 = config[i].totalSupply;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000012,certora_local18)}

      // Install TransferStrategy logic at IncentivesController
      _installTransferStrategy(config[i].reward, config[i].transferStrategy);

      // Set reward oracle, enforces input oracle to have latestPrice function
      _setRewardOracle(config[i].reward, config[i].rewardOracle);
      
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
    // Optimization 1: Custom error
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
    // Optimization 1: Custom error
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
    // Optimization 1: Custom error
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
    // Optimization 1: Custom error
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

  /**
   * @dev Get user balances and total supply of all the assets specified by the assets parameter
   * @param assets List of assets to retrieve user balance and total supply
   * @param user Address of the user
   * @return userAssetBalances contains a list of structs with user balance and total supply of the given assets
   */
  function _getUserAssetBalances(
    address[] calldata assets,
    address user
  ) internal view override returns (RewardsDataTypes.UserAssetBalance[] memory userAssetBalances) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100000, 1037618708496) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00100001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00103000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00102000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00101001, user) }
    // Optimization 2: Cache array length in loops
    uint256 assetsLength = assets.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,assetsLength)}
    userAssetBalances = new RewardsDataTypes.UserAssetBalance[](assetsLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000e,0)}
    // Optimization 3: Use efficient loop increment (++i instead of i++)
    // Optimization 11: Use unchecked arithmetic for validated operations
    for (uint256 i; i < assetsLength;) {
      userAssetBalances[i].asset = assets[i];address certora_local19 = userAssetBalances[i].asset;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,certora_local19)}
      (userAssetBalances[i].userBalance, userAssetBalances[i].totalSupply) = IScaledBalanceToken(
        assets[i]
      ).getScaledUserBalanceAndSupply(user);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020014,0)}
      
      unchecked { ++i; }
    }
  }

  /**
   * @dev Claims one type of reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards.
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount Amount of rewards to claim
   * @param claimer Address of the claimer who claims rewards on behalf of user
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @param reward Address of the reward token
   * @return totalRewards Rewards claimed
   **/
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
      // Optimization 2: Cache array length in loops
      uint256 assetsLength = assets.length;
      // Optimization 3: Use efficient loop increment (++i instead of i++)
      // Optimization 11: Use unchecked arithmetic for validated operations
      for (uint256 i; i < assetsLength;) {
        address asset = assets[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000015,asset)}
        // Optimization 9: Cache array member variables - access nested mapping once
        uint256 accruedRewards = _assets[asset].rewards[reward].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000016,accruedRewards)}
        
        totalRewards += accruedRewards;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000018,totalRewards)}

        if (totalRewards <= amount) {
          _assets[asset].rewards[reward].usersData[user].accrued = 0;
        } else {
          // Optimization 8: Reduce mathematical expressions
          uint256 difference = totalRewards - amount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000019,difference)}
          totalRewards = amount;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001a,totalRewards)}
          _assets[asset].rewards[reward].usersData[user].accrued = difference.toUint128();
          break;
        }
        
        unchecked { ++i; }
      }

      if (totalRewards != 0) {
        _transferRewards(to, reward, totalRewards);
        emit RewardsClaimed(user, reward, to, claimer, totalRewards);
      }
    }
  }

  /**
   * @dev Claims one type of reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards.
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param claimer Address of the claimer on behalf of user
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return
   *   rewardsList List of reward addresses
   *   claimedAmount List of claimed amounts, follows "rewardsList" items order
   **/
  function _claimAllRewards(
    address[] calldata assets,
    address claimer,
    address user,
    address to
  ) internal returns (address[] memory rewardsList, uint256[] memory claimedAmounts) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130000, 1037618708499) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00130001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00133000, assets.offset) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00132000, assets.length) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131001, claimer) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131002, user) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00131003, to) }
    // Optimization 5: Cache storage variables
    uint256 rewardsListLength = _rewardsList.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,rewardsListLength)}
    rewardsList = new address[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0002000f,0)}
    claimedAmounts = new uint256[](rewardsListLength);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020010,0)}

    _updateDataMultiple(user, _getUserAssetBalances(assets, user));

    // Optimization 2: Cache array length in loops
    uint256 assetsLength = assets.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000007,assetsLength)}
    // Optimization 3: Use efficient loop increment (++i instead of i++)
    // Optimization 11: Use unchecked arithmetic for validated operations
    for (uint256 i; i < assetsLength;) {
      address asset = assets[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,asset)}
      for (uint256 j; j < rewardsListLength;) {
        if (rewardsList[j] == address(0)) {
          rewardsList[j] = _rewardsList[j];
        }
        // Optimization 9: Cache array member variables - read accrued value once
        uint256 rewardAmount = _assets[asset].rewards[rewardsList[j]].usersData[user].accrued;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,rewardAmount)}
        if (rewardAmount != 0) {
          claimedAmounts[j] += rewardAmount;
          _assets[asset].rewards[rewardsList[j]].usersData[user].accrued = 0;
        }
        
        unchecked { ++j; }
      }
      
      unchecked { ++i; }
    }
    
    for (uint256 i; i < rewardsListLength;) {
      _transferRewards(to, rewardsList[i], claimedAmounts[i]);
      emit RewardsClaimed(user, rewardsList[i], to, claimer, claimedAmounts[i]);
      
      unchecked { ++i; }
    }
  }

  /**
   * @dev Function to transfer rewards to the desired account using delegatecall and
   * @param to Account address to send the rewards
   * @param reward Address of the reward token
   * @param amount Amount of rewards to transfer
   */
  function _transferRewards(address to, address reward, uint256 amount) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110000, 1037618708497) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00110001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111000, to) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111001, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00111002, amount) }
    ITransferStrategyBase transferStrategy = _transferStrategy[reward];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010008,0)}

    bool success = transferStrategy.performTransfer(to, reward, amount);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000009,success)}

    // Optimization 1: Custom error
    // Optimization 10: Write values directly instead of calculating
    if (!success) revert TransferError();
  }

  /**
   * @dev Returns true if `account` is a contract.
   * @param account The address of the account
   * @return bool, true if contract, false otherwise
   */
  function _isContract(address account) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140000, 1037618708500) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00140001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00141000, account) }
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000a,size)}
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Internal function to call the optional install hook at the TransferStrategy
   * @param reward The address of the reward token
   * @param transferStrategy The address of the reward TransferStrategy
   */
  function _installTransferStrategy(
    address reward,
    ITransferStrategyBase transferStrategy
  ) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150000, 1037618708501) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00150001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151000, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00151001, transferStrategy) }
    // Optimization 1: Custom error
    if (address(transferStrategy) == address(0)) revert StrategyCannotBeZero();
    // Optimization 10: Write values directly instead of calculating
    if (!_isContract(address(transferStrategy))) revert StrategyMustBeContract();

    _transferStrategy[reward] = transferStrategy;

    emit TransferStrategyInstalled(reward, address(transferStrategy));
  }

  /**
   * @dev Update the Price Oracle of a reward token. The Price Oracle must follow Chainlink AggregatorInterface interface.
   * @notice The Price Oracle of a reward is used for displaying correct data about the incentives at the UI frontend.
   * @param reward The address of the reward token
   * @param rewardOracle The address of the price oracle
   */

  function _setRewardOracle(address reward, AggregatorInterface rewardOracle) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160000, 1037618708502) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00160001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161000, reward) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00161001, rewardOracle) }
    // Optimization 1: Custom error
    if (rewardOracle.latestAnswer() <= 0) revert OracleMustReturnPrice();
    _rewardOracle[reward] = rewardOracle;
    emit RewardOracleUpdated(reward, address(rewardOracle));
  }
}