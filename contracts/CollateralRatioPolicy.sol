// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC20/ERC20Custom.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ICollateralRatioPolicy.sol";

contract CollateralRatioPolicy is Ownable, ICollateralRatioPolicy, Initializable {
    using SafeMath for uint256;

    address public oracleDollar;
    address public dollar;
    address public treasury;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    // collateral_ratio
    uint256 public override target_collateral_ratio; // 6 decimals of precision
    uint256 public override effective_collateral_ratio; // 6 decimals of precision
    uint256 public last_refresh_cr_timestamp;
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public ratio_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public price_target; // The price of DOLLAR; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the Collateral ratio is allowed to drop
    bool public collateral_ratio_paused = false; // during bootstraping phase, collateral_ratio will be fixed at 100%
    bool public using_effective_collateral_ratio = true; // toggle the effective collateral ratio usage
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    /* ========== EVENTS ============= */

    event TreasuryChanged(address indexed newTreasury);

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        ratio_step = 2500; // = 0.25% at 6 decimals of precision
        target_collateral_ratio = 1000000;
        effective_collateral_ratio = 1000000;
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // = $1. (6 decimals of precision). Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000;
    }

    function initialize(address _treasury, address _dollar) external onlyOwner initializer {
        setTreasury(_treasury);
        setDollar(_dollar);
    }

    /* ========== VIEWS ========== */

    function calcEffectiveCollateralRatio() public view returns (uint256) {
        if (!using_effective_collateral_ratio) {
            return target_collateral_ratio;
        }
        uint256 total_collateral_value = ITreasury(treasury).globalCollateralValue();
        uint256 total_supply_dollar = IERC20(dollar).totalSupply();
        uint256 ecr = total_collateral_value.mul(PRICE_PRECISION).div(total_supply_dollar);
        if (ecr > COLLATERAL_RATIO_MAX) {
            return COLLATERAL_RATIO_MAX;
        }
        return ecr;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(
            block.timestamp - last_refresh_cr_timestamp >= refresh_cooldown,
            "Must wait for the refresh cooldown since last refresh"
        );

        uint256 current_dollar_price = IOracle(oracleDollar).consult();

        // Step increments are 0.25% (upon genesis, changable by setRatioStep())
        if (current_dollar_price > price_target.add(price_band)) {
            // decrease collateral ratio
            if (target_collateral_ratio <= ratio_step) {
                // if within a step of 0, go to 0
                target_collateral_ratio = 0;
            } else {
                target_collateral_ratio = target_collateral_ratio.sub(ratio_step);
            }
        }
        // IRON price is below $1 - `price_band`. Need to increase `collateral_ratio`
        else if (current_dollar_price < price_target.sub(price_band)) {
            // increase collateral ratio
            if (target_collateral_ratio.add(ratio_step) >= COLLATERAL_RATIO_MAX) {
                target_collateral_ratio = COLLATERAL_RATIO_MAX; // cap collateral ratio at 1.000000
            } else {
                target_collateral_ratio = target_collateral_ratio.add(ratio_step);
            }
        }

        // If using ECR, then calcECR. If not, update ECR = TCR
        if (using_effective_collateral_ratio) {
            effective_collateral_ratio = calcEffectiveCollateralRatio();
        } else {
            effective_collateral_ratio = target_collateral_ratio;
        }

        last_refresh_cr_timestamp = block.timestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRatioStep(uint256 _ratio_step) public onlyOwner {
        ratio_step = _ratio_step;
    }

    function setPriceTarget(uint256 _price_target) public onlyOwner {
        price_target = _price_target;
    }

    function setRefreshCooldown(uint256 _refresh_cooldown) public onlyOwner {
        refresh_cooldown = _refresh_cooldown;
    }

    function setPriceBand(uint256 _price_band) external onlyOwner {
        price_band = _price_band;
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "invalidAddress");
        treasury = _treasury;
        emit TreasuryChanged(treasury);
    }

    function setDollar(address _dollar) public onlyOwner {
        require(_dollar != address(0), "invalidAddress");
        dollar = _dollar;
    }

    // use to retstore CRs incase of using new Treasury
    function reset(uint256 _target_collateral_ratio, uint256 _effective_collateral_ratio) external onlyOwner {
        require(
            _target_collateral_ratio <= COLLATERAL_RATIO_MAX && _effective_collateral_ratio <= COLLATERAL_RATIO_MAX,
            "invalidRatio"
        );
        target_collateral_ratio = _target_collateral_ratio;
        effective_collateral_ratio = _effective_collateral_ratio;
    }

    function toggleCollateralRatio() public onlyOwner {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    function toggleEffectiveCollateralRatio() public onlyOwner {
        using_effective_collateral_ratio = !using_effective_collateral_ratio;
    }

    function setOracleDollar(address _oracleDollar) public onlyOwner {
        require(_oracleDollar != address(0), "invalidAddress");
        oracleDollar = _oracleDollar;
    }
}
