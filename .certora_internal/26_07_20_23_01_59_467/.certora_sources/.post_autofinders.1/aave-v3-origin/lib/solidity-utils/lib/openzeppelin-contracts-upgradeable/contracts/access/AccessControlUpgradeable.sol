// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a0000, 1037618708554) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a0001, 0) }
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal logInternal75()onlyInitializing {
    }modifier logInternal75() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b0000, 1037618708555) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b0001, 0) } _; }

    function __AccessControl_init_unchained() internal logInternal77()onlyInitializing {
    }modifier logInternal77() { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d0000, 1037618708557) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d0001, 0) } _; }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f0000, 1037618708543) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f1000, interfaceId) }
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00410000, 1037618708545) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00410001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00411000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00411001, account) }
        AccessControlStorage storage $ = _getAccessControlStorage();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010018,0)}
        return $._roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e0000, 1037618708558) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e1000, role) }
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c0000, 1037618708556) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c1000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c1001, account) }
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e0000, 1037618708542) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e1000, role) }
        AccessControlStorage storage $ = _getAccessControlStorage();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010019,0)}
        return $._roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual logInternal82(role,account)onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }modifier logInternal82(bytes32 role,address account) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00520000, 1037618708562) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00520001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00521000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00521001, account) } _; }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual logInternal83(role,account)onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }modifier logInternal83(bytes32 role,address account) { assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00530000, 1037618708563) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00530001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00531000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00531001, account) } _; }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430000, 1037618708547) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00431000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00431001, callerConfirmation) }
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f0000, 1037618708559) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f1000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f1001, adminRole) }
        AccessControlStorage storage $ = _getAccessControlStorage();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001a,0)}
        bytes32 previousAdminRole = getRoleAdmin(role);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001b,previousAdminRole)}
        $._roles[role].adminRole = adminRole;bytes32 certora_local30 = $._roles[role].adminRole;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,certora_local30)}
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00500000, 1037618708560) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00500001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00501000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00501001, account) }
        AccessControlStorage storage $ = _getAccessControlStorage();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001c,0)}
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00510000, 1037618708561) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00510001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00511000, role) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00511001, account) }
        AccessControlStorage storage $ = _getAccessControlStorage();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001001d,0)}
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}
