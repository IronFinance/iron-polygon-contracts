// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC20/ERC20Custom.sol";
import "./interfaces/IShareTreasuryFund.sol";

contract TreasuryFund is Ownable, Initializable {
    using SafeERC20 for IERC20;
    address public share;

    uint256 private constant BURN_EXESS_RATIO = 900000;
    uint256 private constant PRECISION = 1000000;

    function initialize(address _share) external onlyOwner initializer {
        require(_share != address(0), "Invalid address");
        share = _share;
    }

    function claim() external onlyOwner {
        IShareTreasuryFund shareFund = IShareTreasuryFund(share);
        uint256 unclaimed_amount = shareFund.unclaimedTreasuryFund();
        shareFund.claimTreasuryFundRewards();
        uint256 burnAmount = (unclaimed_amount * BURN_EXESS_RATIO) / PRECISION;
        ERC20Custom(share).burn(burnAmount);
    }

    function transfer(address _recipient, uint256 amount) external onlyOwner {
        IERC20(share).transfer(_recipient, amount);
    }

    function transferDevFundOwnership(address _newFund) external onlyOwner {
        IShareTreasuryFund(share).setTreasuryFund(_newFund);
    }

    function balance() public view returns (uint256) {
        return IERC20(share).balanceOf(address(this));
    }

    function setShareAddress(address _share) public onlyOwner {
        share = _share;
    }

    function rescueFund(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
    }
}
