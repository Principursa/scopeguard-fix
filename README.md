# ScopeGuard

[![Build Status](https://github.com/gnosis/zodiac-guard-scope/actions/workflows/ci.yml/badge.svg)](https://github.com/gnosis/zodiac-guard-scope/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gnosis/zodiac-guard-scope/badge.svg?branch=main)](https://coveralls.io/github/gnosis/zodiac-guard-scope)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/gnosis/CODE_OF_CONDUCT)

Attaching a scope guard to an Avatar or Mod, allows one to limit the contracts and functions that may be called (by the multisig owners in the case of a Gnosis Safe, or by the mod if enable of a mod).

### Features

- Set specific addresses that the avatar can be triggered to call
- Scope the functions that are allowed to be called on specific addresses
- Allow/disallow multisig transaction to use delegate calls to specific addresses

### Flow

- Deploy ScopeGuard
- Allow addresses and function calls that the Safe multisig signers should be able to call
- Enable the txguard in the Safe

### Warnings ⚠️

Before you enable your ScopeGuard, please make sure you have setup the ScopeGuard fully to enable each of the addresses and functions you wish for the multisig owners or mod to be able to call.

Best practice is to enable another account that you control as a module to your Safe before enabling your ScopeGuard.

Some specific things you should be aware of:

- Enabling a ScopeGuard can brick your Avatar, making it unusable and rendering any funds inaccessible.
  Once enabled on your Safe, your ScopeGuard will revert any transactions to addresses or functions that have not been explicitly allowed.
- By default it is not possible to use delegate call with any contract once your ScopeGuard is enabled.
  This means if the ScopeGuard is added without allowing delegate calls for the `MultiSendCallOnly` contract, there might be issues when using some Safe apps via the Safe web interface.
- Delegate call usage checks are per address. It is not possible to limit this to a specific function of a contract.
- Transaction value is not checked.
  This means that the multisig owners can send any amount of native assets allowed addresses.
- If a contract address is marked as scoped it is not possible to call any function on this contract UNLESS it was explicitly marked as allowed.
- If the Safe contract itself is marked as scoped without any allowed functions, it is bricked (even if the Safe address itself is in the allowed list).
- Enabling the ScopeGuard will increase the gas cost of each multisig transaction.

### Solidity Compiler

The contracts have been developed with [Solidity 0.8.6](https://github.com/ethereum/solidity/releases/tag/v0.8.6) in mind. This version of Solidity made all arithmetic checked by default, therefore eliminating the need for explicit overflow or underflow (or other arithmetic) checks.

### Setup Guide

Follow our [ScopeGuard Setup Guide](./docs/setup_guide.md) to setup and use a ScopeGuard.

### Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

### License

Created under the [LGPL-3.0+ license](LICENSE).

### Audits

An audit has been performed by the [G0 group](https://github.com/g0-group).

All issues and notes of the audit have been addressed in commit [ad2579a3fc684b2dd87c5f87c8736cd61e46e4cb](https://github.com/gnosis/zodiac-guard-scope/commit/ad2579a3fc684b2dd87c5f87c8736cd61e46e4cb).

The audit results are available as a pdf in [this repo](audits/ZodiacScopeGuardSep2021.pdf) or on the [g0-group repo](https://github.com/g0-group/Audits/blob/e11752abb010f74e32a6fc61142032a10deed578/ZodiacScopeGuardSep2021.pdf).

### Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
