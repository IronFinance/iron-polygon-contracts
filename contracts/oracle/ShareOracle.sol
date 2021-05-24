// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IPairOracle.sol";

contract ShareOracle is Ownable, IOracle {
    address public oracleShare;
    address public chainlinkToUsd;
    address public share;

    uint256 private constant PRICE_PRECISION = 1e6;

    constructor(
        address _share,
        address _oracleShare,
        address _chainlinkToUsd
    ) {
        share = _share;
        chainlinkToUsd = _chainlinkToUsd;
        oracleShare = _oracleShare;
    }

    function consult() external view override returns (uint256) {
        uint256 _priceTokenToUsd = priceTokenToUsd();
        uint256 _priceShareToToken = IPairOracle(oracleShare).consult(share, PRICE_PRECISION);
        return (_priceTokenToUsd * _priceShareToToken) / PRICE_PRECISION;
    }

    function priceTokenToUsd() internal view returns (uint256) {
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(chainlinkToUsd);
        (, int256 _price, , , ) = _priceFeed.latestRoundData();
        uint8 _decimals = _priceFeed.decimals();
        return (uint256(_price) * PRICE_PRECISION) / (10**_decimals);
    }

    function setChainlinkToUsd(address _chainlinkToUsd) external onlyOwner {
        chainlinkToUsd = _chainlinkToUsd;
    }

    function setOracleShare(address _oracleShare) external onlyOwner {
        oracleShare = _oracleShare;
    }
}
