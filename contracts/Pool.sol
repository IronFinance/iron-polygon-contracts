// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IShare.sol";
import "./interfaces/IDollar.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IPool.sol";

contract Pool is Ownable, ReentrancyGuard, Initializable, IPool {
    using SafeERC20 for ERC20;

    /* ========== ADDRESSES ================ */
    address public oracle;
    address public collateral;
    address public dollar;
    address public treasury;
    address public share;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public redeem_share_balances;
    mapping(address => uint256) public redeem_collateral_balances;

    uint256 public override unclaimed_pool_collateral;
    uint256 public unclaimed_pool_share;

    mapping(address => uint256) public last_redeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // Number of decimals needed to get to 18
    uint256 private missing_decimals;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl state variables
    bool public mint_paused = false;
    bool public redeem_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyTreasury() {
        require(msg.sender == treasury, "!treasury");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _dollar,
        address _share,
        address _collateral,
        address _treasury
    ) external initializer onlyOwner {
        dollar = _dollar;
        share = _share;
        collateral = _collateral;
        treasury = _treasury;
        missing_decimals = 18 - ERC20(_collateral).decimals();
    }

    /* ========== VIEWS ========== */

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            unclaimed_pool_collateral, // unclaimed amount of COLLATERAL
            unclaimed_pool_share, // unclaimed amount of SHARE
            getCollateralPrice(), // collateral price
            mint_paused,
            redeem_paused
        );
    }

    function collateralReserve() public view returns (address) {
        return ITreasury(treasury).collateralReserve();
    }

    function getCollateralPrice() public view override returns (uint256) {
        return IOracle(oracle).consult();
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function mint(
        uint256 _collateral_amount,
        uint256 _share_amount,
        uint256 _dollar_out_min
    ) external {
        require(mint_paused == false, "Minting is paused");
        (, uint256 _share_price, , uint256 _tcr, , , uint256 _minting_fee, ) = ITreasury(treasury).info();
        require(_share_price > 0, "Invalid share price");
        uint256 _price_collateral = getCollateralPrice();
        uint256 _total_dollar_value = 0;
        uint256 _required_share_amount = 0;
        if (_tcr > 0) {
            uint256 _collateral_value = ((_collateral_amount * (10**missing_decimals)) * _price_collateral) / PRICE_PRECISION;
            _total_dollar_value = (_collateral_value * COLLATERAL_RATIO_PRECISION) / _tcr;
            if (_tcr < COLLATERAL_RATIO_MAX) {
                _required_share_amount = ((_total_dollar_value - _collateral_value) * PRICE_PRECISION) / _share_price;
            }
        } else {
            _total_dollar_value = (_share_amount * _share_price) / PRICE_PRECISION;
            _required_share_amount = _share_amount;
        }
        uint256 _actual_dollar_amount = _total_dollar_value - ((_total_dollar_value * _minting_fee) / PRICE_PRECISION);
        require(_dollar_out_min <= _actual_dollar_amount, "slippage");

        if (_required_share_amount > 0) {
            require(_required_share_amount <= _share_amount, "Not enough SHARE input");
            IShare(share).poolBurnFrom(msg.sender, _required_share_amount);
        }
        if (_collateral_amount > 0) {
            _transferCollateralToReserve(msg.sender, _collateral_amount);
        }
        IDollar(dollar).poolMint(msg.sender, _actual_dollar_amount);
    }

    function redeem(
        uint256 _dollar_amount,
        uint256 _share_out_min,
        uint256 _collateral_out_min
    ) external {
        require(redeem_paused == false, "Redeeming is paused");
        (, uint256 _share_price, , , uint256 _ecr, , , uint256 _redemption_fee) = ITreasury(treasury).info();
        uint256 _collateral_price = getCollateralPrice();
        require(_collateral_price > 0, "Invalid collateral price");
        require(_share_price > 0, "Invalid share price");
        uint256 _dollar_amount_post_fee = _dollar_amount - ((_dollar_amount * _redemption_fee) / PRICE_PRECISION);
        uint256 _collateral_output_amount = 0;
        uint256 _share_output_amount = 0;

        if (_ecr < COLLATERAL_RATIO_MAX) {
            uint256 _share_output_value = _dollar_amount_post_fee - ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION);
            _share_output_amount = (_share_output_value * PRICE_PRECISION) / _share_price;
        }

        if (_ecr > 0) {
            uint256 _collateral_output_value = ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION) / (10**missing_decimals);
            _collateral_output_amount = (_collateral_output_value * PRICE_PRECISION) / _collateral_price;
        }

        // Check if collateral balance meets and meet output expectation
        uint256 _totalCollateralBalance = ITreasury(treasury).globalCollateralBalance();
        require(_collateral_output_amount <= _totalCollateralBalance, "<collateralBalance");
        require(_collateral_out_min <= _collateral_output_amount && _share_out_min <= _share_output_amount, ">slippage");

        if (_collateral_output_amount > 0) {
            redeem_collateral_balances[msg.sender] = redeem_collateral_balances[msg.sender] + _collateral_output_amount;
            unclaimed_pool_collateral = unclaimed_pool_collateral + _collateral_output_amount;
        }

        if (_share_output_amount > 0) {
            redeem_share_balances[msg.sender] = redeem_share_balances[msg.sender] + _share_output_amount;
            unclaimed_pool_share = unclaimed_pool_share + _share_output_amount;
        }

        last_redeemed[msg.sender] = block.number;

        // Move all external functions to the end
        IDollar(dollar).poolBurnFrom(msg.sender, _dollar_amount);
        if (_share_output_amount > 0) {
            _mintShareToCollateralReserve(_share_output_amount);
        }
    }

    function collectRedemption() external {
        require((last_redeemed[msg.sender] + redemption_delay) <= block.number, "<redemption_delay");

        bool _send_share = false;
        bool _send_collateral = false;
        uint256 _share_amount;
        uint256 _collateral_amount;

        // Use Checks-Effects-Interactions pattern
        if (redeem_share_balances[msg.sender] > 0) {
            _share_amount = redeem_share_balances[msg.sender];
            redeem_share_balances[msg.sender] = 0;
            unclaimed_pool_share = unclaimed_pool_share - _share_amount;
            _send_share = true;
        }

        if (redeem_collateral_balances[msg.sender] > 0) {
            _collateral_amount = redeem_collateral_balances[msg.sender];
            redeem_collateral_balances[msg.sender] = 0;
            unclaimed_pool_collateral = unclaimed_pool_collateral - _collateral_amount;
            _send_collateral = true;
        }

        if (_send_share) {
            _requestTransferShare(msg.sender, _share_amount);
        }

        if (_send_collateral) {
            _requestTransferCollateral(msg.sender, _collateral_amount);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transferCollateralToReserve(address _sender, uint256 _amount) internal {
        address _reserve = collateralReserve();
        require(_reserve != address(0), "Invalid reserve address");
        ERC20(collateral).safeTransferFrom(_sender, _reserve, _amount);
    }

    function _mintShareToCollateralReserve(uint256 _amount) internal {
        address _reserve = collateralReserve();
        require(_reserve != address(0), "Invalid reserve address");
        IShare(share).poolMint(_reserve, _amount);
    }

    function _requestTransferCollateral(address _receiver, uint256 _amount) internal {
        ITreasury(treasury).requestTransfer(collateral, _receiver, _amount);
    }

    function _requestTransferShare(address _receiver, uint256 _amount) internal {
        ITreasury(treasury).requestTransfer(share, _receiver, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external onlyOwner {
        mint_paused = !mint_paused;
    }

    function toggleRedeeming() external onlyOwner {
        redeem_paused = !redeem_paused;
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid address");
        oracle = _oracle;
    }

    function setRedemptionDelay(uint256 _redemption_delay) external onlyOwner {
        redemption_delay = _redemption_delay;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    // EVENTS
    event TreasuryChanged(address indexed newTreasury);
}
