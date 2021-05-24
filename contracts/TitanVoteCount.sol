// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMasterChef.sol";

contract TitanVoteCount is Ownable, Initializable {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    IMasterChef public govStakingPool;
    IERC20 public titan;

    function initialize(address _titan, address _govStakingPool) external initializer onlyOwner {
        titan = IERC20(_titan);
        govStakingPool = IMasterChef(_govStakingPool);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 _balance = 0;

        // TITAN holders
        _balance = _balance + titan.balanceOf(account);

        // TITAN holders in gov staking pool
        (uint256 _amount, ) = govStakingPool.userInfo(0, account);
        _balance = _balance + _amount;

        return _balance;
    }
}
