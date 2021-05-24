// SPDX-License-Identifier: MITT

pragma solidity ^0.8.4;

interface ITreasuryVault {
    function vaultBalance() external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw() external;
}
