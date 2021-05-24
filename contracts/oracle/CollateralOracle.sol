// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IOracle.sol";

contract CollateralOracle is Ownable, IOracle {
    address public chainlinkCollateralUsd;

    uint256 private constant PRICE_PRECISION = 1e6;

    constructor(address _chainlinkCollateralUsd) {
        chainlinkCollateralUsd = _chainlinkCollateralUsd;
    }

    function consult() external view override returns (uint256) {
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(chainlinkCollateralUsd);
        (, int256 _price, , , ) = _priceFeed.latestRoundData();
        uint8 _decimals = _priceFeed.decimals();
        return (uint256(_price) * PRICE_PRECISION) / (10**_decimals);
    }

    function setChainlinkCollateralUsd(address _chainlinkCollateralUsd) external onlyOwner {
        chainlinkCollateralUsd = _chainlinkCollateralUsd;
    }
}
