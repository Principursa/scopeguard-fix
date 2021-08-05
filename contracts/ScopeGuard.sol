// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/base/GuardManager.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

contract ScopeGuard is BaseGuard, Ownable {
    event TargetAllowed(address target);
    event TargetDisallowed(address target);
    event TargetScopeSet(address target, bool scoped);
    event DelegateCallsAllowedOnTarget(address target);
    event DelegateCallsDisallowedOnTarget(address target);
    event FunctionAllowedOnTarget(address target, bytes4 functionSig);
    event FunctionDisallowedOnTarget(address target, bytes4 functionSig);

    struct Target {
        bool allowed;
        bool scoped;
        bool delegateCallAllowed;
        mapping(bytes4 => bool) allowedFunctions;
    }

    mapping(address => Target) public allowedTargets;

    /// @dev Allows multisig owners to make call to an address.
    /// @notice Only callable by owner.
    /// @param target Address to be allowed.
    function allowTarget(address target) public onlyOwner {
        allowedTargets[target].allowed = true;
        emit TargetAllowed(target);
    }

    /// @dev Disallows multisig owners to make call to an address.
    /// @notice Only callable by owner.
    /// @param target Address to be disallowed.
    function disallowTarget(address target) public onlyOwner {
        allowedTargets[target].allowed = false;
        emit TargetDisallowed(target);
    }

    /// @dev Allows multisig owners to make delegate calls to an address.
    /// @notice Only callable by owner.
    /// @param target Address to which delegate calls will be allowed.
    function allowDelegateCall(address target) public onlyOwner {
        allowedTargets[target].delegateCallAllowed = true;
        emit DelegateCallsAllowedOnTarget(target);
    }

    /// @dev Disallows multisig owners to make delegate calls to an address.
    /// @notice Only callable by owner.
    /// @param target Address to which delegate calls will be disallowed.
    function disallowDelegateCall(address target) public onlyOwner {
        allowedTargets[target].delegateCallAllowed = false;
        emit DelegateCallsDisallowedOnTarget(target);
    }

    /// @dev Sets whether or not calls to an address should be scoped to specific function signatures.
    /// @notice Only callable by owner.
    /// @param target Address that will be scoped/unscoped.
    /// @param scoped Boolean for whether or not the target address should be scoped.
    function setScoped(address target, bool scoped) public onlyOwner {
        allowedTargets[target].scoped = scoped;
        emit TargetScopeSet(target, scoped);
    }

    function allowFunction(address target, bytes4 functionSig)
        public
        onlyOwner
    {
        /// @dev Allows multisig owners to call specific function on a scoped address.
        /// @notice Only callable by owner.
        /// @param target Address that the function should be allowed.
        /// @param functionSig Function signature to be allowed.
        allowedTargets[target].allowedFunctions[functionSig] = true;
        emit FunctionAllowedOnTarget(target, functionSig);
    }

    /// @dev Disallows multisig owners to call specific function on a scoped address.
    /// @notice Only callable by owner.
    /// @param target Address that the function should be disallowed.
    /// @param functionSig Function signature to be disallowed.
    function disallowFunction(address target, bytes4 functionSig)
        public
        onlyOwner
    {
        allowedTargets[target].allowedFunctions[functionSig] = false;
        emit FunctionDisallowedOnTarget(target, functionSig);
    }

    /// @dev Returns bool to indicate if an address is an allowed target.
    /// @param target Address to check.
    function isAllowedTarget(address target) public view returns (bool) {
        return (allowedTargets[target].allowed);
    }

    /// @dev Returns bool to indicate if an address is scoped.
    /// @param target Address to check.
    function isScoped(address target) public view returns (bool) {
        return (allowedTargets[target].scoped);
    }

    /// @dev Returns bool to indicate if a function signature is allowed for a target address.
    /// @param target Address to check.
    /// @param functionSig Signature to check.
    function isAllowedFunction(address target, bytes4 functionSig)
        public
        view
        returns (bool)
    {
        return (allowedTargets[target].allowedFunctions[functionSig]);
    }

    /// @dev Returns bool to indicate if delegate calls are allowed to a target address.
    /// @param target Address to check.
    function isAllowedToDelegateCall(address target)
        public
        view
        returns (bool)
    {
        return (allowedTargets[target].delegateCallAllowed);
    }

    // solhint-disallow-next-line payable-fallback
    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function checkTransaction(
        address to,
        uint256,
        bytes memory data,
        Enum.Operation operation,
        uint256,
        uint256,
        uint256,
        address,
        // solhint-disallow-next-line no-unused-vars
        address payable,
        bytes memory,
        address
    ) external view override {
        require(
            operation != Enum.Operation.DelegateCall ||
                allowedTargets[to].delegateCallAllowed,
            "Delegate call not allowed to this address"
        );
        require(isAllowedTarget(to), "Target address is not allowed");
        if (data.length >= 4) {
            require(
                !allowedTargets[to].scoped ||
                    isAllowedFunction(to, bytes4(data)),
                "Target function is not allowed"
            );
        }
        if (data.length < 4) {
            require(
                !allowedTargets[to].scoped || isAllowedFunction(to, bytes4(0)),
                "Cannot send to this address"
            );
        }
    }

    function checkAfterExecution(bytes32, bool) external view override {}
}