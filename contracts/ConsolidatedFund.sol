// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConsolidatedFund is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // CONTRACTS
    mapping(address => address) public pools;

    /* ========== MODIFIER ========== */

    modifier onlyPools() {
        require(pools[msg.sender] != address(0), "Only pool can request transfer");
        _;
    }

    /* ========== VIEWS ================ */

    function balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyPools {
        require(_receiver != address(0), "Invalid address");
        require(pools[msg.sender] == _token, "Invalid request token");
        if (_amount > 0) {
            uint8 missing_decimals = 18 - ERC20(_token).decimals();
            IERC20(_token).safeTransfer(_receiver, _amount.div(10**missing_decimals));
        }
    }

    // Add new Pool
    function addPool(address pool_address, address reward_token) public onlyOwner {
        require(pools[pool_address] == address(0), "poolExisted");
        require(reward_token != address(0), "invalid reward token");
        pools[pool_address] = reward_token;
        emit PoolAdded(pool_address);
    }

    // Remove a pool
    function removePool(address pool_address) public onlyOwner {
        require(pools[pool_address] != address(0), "!pool");
        // Delete from the mapping
        delete pools[pool_address];
        emit PoolRemoved(pool_address);
    }

    function rescueFund(address _token) public onlyOwner {
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    event PoolAdded(address pool);
    event PoolRemoved(address pool);
}
