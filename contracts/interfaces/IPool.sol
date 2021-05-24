// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IPool {
    function getCollateralPrice() external view returns (uint256);

    function unclaimed_pool_collateral() external view returns (uint256);
}
