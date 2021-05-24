// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IUniswapLP.sol";

contract SpotPriceGetter {
    using SafeMath for uint256;

    uint256 private constant PRICE_PRECISION = 1e6;

    function consult(address _token, address _refLpPair) public view returns (uint256) {
        IUniswapLP _lpPair = IUniswapLP(_refLpPair);
        address _token0 = _lpPair.token0();
        address _token1 = _lpPair.token1();
        require(_token0 == _token || _token1 == _token, "Invalid pair");
        (uint256 _reserve0, uint256 _reserve1, ) = _lpPair.getReserves();
        require(_reserve0 > 0 && _reserve1 > 0, "No reserves");
        uint8 _token0MissingDecimals = 18 - (ERC20(_token0).decimals());
        uint8 _token1MissingDecimals = 18 - (ERC20(_token1).decimals());
        uint256 _price = 0;
        if (_token == _token0) {
            _price = _reserve1.mul(10**_token1MissingDecimals).mul(PRICE_PRECISION).div(_reserve0);
        } else {
            _price = _reserve0.mul(10**_token0MissingDecimals).mul(PRICE_PRECISION).div(_reserve1);
        }
        return _price;
    }

    function consultToUsdChainlink(
        address _token,
        address _refLpPair,
        address _chainlinkPriceFeed
    ) external view returns (uint256) {
        uint256 _price = consult(_token, _refLpPair);
        AggregatorV3Interface _priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        (, int256 _priceToUsd, , , ) = _priceFeed.latestRoundData();
        uint8 _decimals = _priceFeed.decimals();
        return _price.mul(uint256(_priceToUsd)).div(uint256(10)**_decimals);
    }
}
