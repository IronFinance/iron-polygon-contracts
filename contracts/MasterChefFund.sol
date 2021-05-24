// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MasterChefFund is Ownable {
    using SafeERC20 for IERC20;

    // CONTRACTS
    address[] public pools_array;
    mapping(address => bool) public pools;

    IERC20 public rewardToken;

    /* ========== MODIFIER ========== */

    modifier onlyPools() {
        require(pools[msg.sender], "Only pool can request transfer");
        _;
    }

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    /* ========== VIEWS ================ */

    function balance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferTo(address _receiver, uint256 _amount) public onlyPools {
        require(_receiver != address(0), "Invalid address");
        IERC20(rewardToken).safeTransfer(_receiver, _amount);
    }

    // Add new Pool
    function addPool(address pool_address) public onlyOwner {
        require(!pools[pool_address], "poolExisted");
        pools[pool_address] = true;
        pools_array.push(pool_address);
        emit PoolAdded(pool_address);
    }

    // Remove a pool
    function removePool(address pool_address) public onlyOwner {
        require(pools[pool_address], "!pool");
        // Delete from the mapping
        delete pools[pool_address];
        // 'Delete' from the array without leaving a hole
        for (uint256 i = 0; i < pools_array.length; i++) {
            if (pools_array[i] == pool_address) {
                pools_array[i] = pools_array[pools_array.length - 1];
                break;
            }
        }
        pools_array.pop();
        emit PoolRemoved(pool_address);
    }

    event PoolAdded(address pool);
    event PoolRemoved(address pool);
}
