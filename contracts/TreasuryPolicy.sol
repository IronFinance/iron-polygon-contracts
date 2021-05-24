// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ITreasuryPolicy.sol";

contract TreasuryPolicy is Ownable, Initializable, ITreasuryPolicy {
    address public treasury;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    // fees
    uint256 public override redemption_fee; // 6 decimals of precision
    uint256 public constant REDEMPTION_FEE_MAX = 9000; // 0.9%

    uint256 public override minting_fee; // 6 decimals of precision
    uint256 public constant MINTING_FEE_MAX = 5000; // 0.5%

    uint256 public override excess_collateral_safety_margin;
    uint256 public constant EXCESS_COLLATERAL_SAFETY_MARGIN_MIN = 150000; // 15%

    /* ========== EVENTS ============= */

    event TreasuryChanged(address indexed newTreasury);

    function initialize(
        address _treasury,
        uint256 _redemption_fee,
        uint256 _minting_fee,
        uint256 _excess_collateral_safety_margin
    ) external initializer onlyOwner {
        treasury = _treasury;
        setMintingFee(_minting_fee);
        setRedemptionFee(_redemption_fee);
        setExcessCollateralSafetyMargin(_excess_collateral_safety_margin);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    function setRedemptionFee(uint256 _redemption_fee) public onlyOwner {
        require(_redemption_fee <= REDEMPTION_FEE_MAX, ">REDEMPTION_FEE_MAX");
        redemption_fee = _redemption_fee;
    }

    function setMintingFee(uint256 _minting_fee) public onlyOwner {
        require(_minting_fee <= MINTING_FEE_MAX, ">MINTING_FEE_MAX");
        minting_fee = _minting_fee;
    }

    function setExcessCollateralSafetyMargin(uint256 _excess_collateral_safety_margin) public onlyOwner {
        require(
            _excess_collateral_safety_margin >= EXCESS_COLLATERAL_SAFETY_MARGIN_MIN,
            "<EXCESS_COLLATERAL_SAFETY_MARGIN_MIN"
        );
        excess_collateral_safety_margin = _excess_collateral_safety_margin;
    }
}
