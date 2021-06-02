// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC20/ERC20Custom.sol";
import "./interfaces/ITreasury.sol";

contract Share is ERC20Custom, Ownable, Initializable {
    /* ========== STATE VARIABLES ========== */

    // ERC20 - Token
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public constant genesis_supply = 50000 ether; // 50000 will be mited at genesis for liq pool seeding

    // CONTRACTS
    address public treasury;

    // DISTRIBUTION
    uint256 public constant COMMUNITY_REWARD_ALLOCATION = 700_000_000 ether; // 700M
    uint256 public constant TREASURY_FUND_ALLOCATION = 300_000_000 ether; // 300M
    uint256 public constant TREASURY_FUND_VESTING_DURATION = 1095 days; // 36 months
    uint256 public startTime; // Start time of vesting duration
    uint256 public endTime; // End of vesting duration
    address public treasuryFund;
    uint256 public treasuryFundLastClaimed;
    uint256 public treasuryFundEmissionRate =
        TREASURY_FUND_ALLOCATION / TREASURY_FUND_VESTING_DURATION;
    address public communityRewardController; // Holding SHARE tokens to distribute into Liquiditiy Mining Pools
    uint256 public communityRewardClaimed;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
        require(ITreasury(treasury).hasPool(msg.sender), "!pools");
        _;
    }

    modifier onlyTreasuryFund {
        require(msg.sender == treasuryFund, "Only treasury fund address can trigger");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        string memory _name,
        string memory _symbol,
        address _treasury,
        address _treasuryFund,
        address _communityRewardController,
        uint256 _startTime
    ) external initializer onlyOwner {
        name = _name;
        symbol = _symbol;
        treasury = _treasury;
        treasuryFund = _treasuryFund;
        communityRewardController = _communityRewardController;
        startTime = _startTime;
        endTime = _startTime + TREASURY_FUND_VESTING_DURATION;
        treasuryFundLastClaimed = _startTime;
        _mint(msg.sender, genesis_supply);
    }

    function claimCommunityRewards(uint256 amount) external onlyOwner {
        require(amount > 0, "invalidAmount");
        require(communityRewardController != address(0), "!rewardController");
        uint256 _remainingRewards = COMMUNITY_REWARD_ALLOCATION - communityRewardClaimed;
        require(amount <= _remainingRewards, "exceedRewards");
        communityRewardClaimed = communityRewardClaimed + amount;
        _mint(communityRewardController, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function setTreasuryFund(address _treasuryFund) external onlyTreasuryFund {
        require(_treasuryFund != address(0), "zero");
        treasuryFund = _treasuryFund;
    }

    function setCommunityRewardController(address _communityRewardController) external onlyOwner {
        require(_communityRewardController != address(0), "zero");
        communityRewardController = _communityRewardController;
    }

    // This function is what other Pools will call to mint new SHARE
    function poolMint(address m_address, uint256 m_amount) external onlyPools {
        super._mint(m_address, m_amount);
        emit ShareMinted(address(this), m_address, m_amount);
    }

    // This function is what other pools will call to burn SHARE
    function poolBurnFrom(address b_address, uint256 b_amount) external onlyPools {
        super._burnFrom(b_address, b_amount);
        emit ShareBurned(b_address, address(this), b_amount);
    }

    function unclaimedTreasuryFund() public view returns (uint256 _pending) {
        uint256 _now = block.timestamp;
        if (_now > endTime) _now = endTime;
        if (treasuryFundLastClaimed >= _now) return 0;
        _pending = (_now - treasuryFundLastClaimed) * treasuryFundEmissionRate;
    }

    function claimTreasuryFundRewards() external onlyTreasuryFund {
        uint256 _pending = unclaimedTreasuryFund();
        if (_pending > 0 && treasuryFund != address(0)) {
            _mint(treasuryFund, _pending);
            treasuryFundLastClaimed = block.timestamp;
        }
    }

    /* ========== EVENTS ========== */

    event TreasuryChanged(address indexed newTreasury);
    event ShareBurned(address indexed from, address indexed to, uint256 amount);
    event ShareMinted(address indexed from, address indexed to, uint256 amount);
}
