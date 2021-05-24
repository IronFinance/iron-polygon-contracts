// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface ICollateralRatioPolicy {
    function target_collateral_ratio() external view returns (uint256);

    function effective_collateral_ratio() external view returns (uint256);
}
