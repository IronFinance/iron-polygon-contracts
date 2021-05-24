// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMasterChefFund {
    function balance() external view returns (uint256);

    function transferTo(address _receiver, uint256 _amount) external;
}
