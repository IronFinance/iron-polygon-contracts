// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IDollar {
    function poolBurnFrom(address _address, uint256 _amount) external;

    function poolMint(address _address, uint256 m_amount) external;
}
