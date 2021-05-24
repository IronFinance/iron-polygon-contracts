// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMasterChef {
    function userInfo(uint256 pid, address account) external view returns (uint256 amount, uint256 debt);
}
