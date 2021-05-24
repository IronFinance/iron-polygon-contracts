// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITreasury {
    function hasPool(address _address) external view returns (bool);

    function collateralReserve() external view returns (address);

    function globalCollateralBalance() external view returns (uint256);

    function globalCollateralValue() external view returns (uint256);

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}
