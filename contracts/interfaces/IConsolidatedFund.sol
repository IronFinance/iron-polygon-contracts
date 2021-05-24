// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IConsolidatedFund {
    function balance(address _token) external view returns (uint256);

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;
}
