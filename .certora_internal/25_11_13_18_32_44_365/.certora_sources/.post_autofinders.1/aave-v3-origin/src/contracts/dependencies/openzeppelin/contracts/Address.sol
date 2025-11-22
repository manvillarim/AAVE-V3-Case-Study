// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b40000, 1037618708660) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b40001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b41000, account) }
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000003,size)}
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b50000, 1037618708661) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b50001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b51000, recipient) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b51001, amount) }
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010004,0)}
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b70000, 1037618708663) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b70001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b71000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b71001, data) }
    return functionCall(target, data, 'Address: low-level call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b80000, 1037618708664) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b80001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b81000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b81001, data) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b81002, errorMessage) }
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b60000, 1037618708662) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b60001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b61000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b61001, data) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b61002, value) }
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b90000, 1037618708665) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b90001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b91000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b91001, data) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b91002, value) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00b91003, errorMessage) }
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010005,0)}
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba0000, 1037618708666) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba1000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00ba1001, data) }
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb0000, 1037618708667) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb1000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb1001, data) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bb1002, errorMessage) }
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010006,0)}
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc0000, 1037618708668) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc1000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bc1001, data) }
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd0000, 1037618708669) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd1000, target) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd1001, data) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00bd1002, errorMessage) }
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010007,0)}
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be0000, 1037618708670) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be1000, success) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be1001, returndata) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00be1002, errorMessage) }
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}
