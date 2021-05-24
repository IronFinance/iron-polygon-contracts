// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICollateralReserve.sol";

contract CollateralReserve is Ownable, ICollateralReserve, Initializable {
    using SafeERC20 for IERC20;

    // CONTRACTS
    address public treasury;

    /* ========== MODIFIER ========== */

    modifier onlyTreasury() {
        require(treasury == msg.sender, "Only treasury can trigger this function");
        _;
    }

    function initialize(address _treasury) external onlyOwner initializer {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }

    /* ========== VIEWS ================ */

    function fundBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public override onlyTreasury {
        require(_receiver != address(0), "Invalid address");
        require(_amount > 0, "Cannot transfer zero amount");
        IERC20(_token).safeTransfer(_receiver, _amount);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    event TreasuryChanged(address indexed newTreasury);
}
