// SPDX-License-Identifier: MITT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../interfaces/ITreasuryVault.sol";
import "./IAaveLendingPool.sol";
import "./IAaveIncentivesController.sol";

contract TreasuryVaultAave is ITreasuryVault, Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    IERC20 public aToken;
    address public treasury;
    ILendingPool public AaveLendingPool; // Aave lending Pool
    IAaveIncentivesController public AaveIncentivesController;
    uint256 public override vaultBalance;

    // EVENTS
    event TreasuryChanged(address indexed newTreasury);
    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event Profited(uint256 amount);
    event IncentivesClaimed(uint256 amount);

    // MODIFIERS

    modifier onlyTreasury {
        require(_msgSender() == treasury, "!treasury");
        _;
    }

    // Constructor

    function initialize(
        address _asset,
        address _treasury,
        address _aaveLendingPool,
        address _aaveIncentivesController
    ) external initializer onlyOwner {
        asset = IERC20(_asset);
        treasury = _treasury;
        AaveLendingPool = ILendingPool(_aaveLendingPool);
        AaveIncentivesController = IAaveIncentivesController(_aaveIncentivesController);
        aToken = IERC20(_getATokenAddress(_asset));
    }

    // TREASURY functions

    function deposit(uint256 _amount) external override onlyTreasury {
        require(_amount > 0, "amount = 0");
        asset.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 newBalance = asset.balanceOf(address(this)); // invest everything in vault
        vaultBalance = newBalance;
        asset.safeApprove(address(AaveLendingPool), 0);
        asset.safeApprove(address(AaveLendingPool), newBalance);
        AaveLendingPool.deposit(address(asset), newBalance, address(this), 0);
        emit Deposited(_amount);
    }

    function withdraw() external override onlyTreasury {
        AaveLendingPool.withdraw(address(asset), balanceOfAToken(), address(this));
        uint256 newBalance = asset.balanceOf(address(this));
        uint256 profit = 0;
        if (newBalance > vaultBalance) {
            profit = newBalance - vaultBalance;
        }
        asset.safeTransfer(treasury, newBalance);
        vaultBalance = asset.balanceOf(address(this));
        emit Withdrawn(newBalance);
        emit Profited(profit);
    }

    function claimIncetiveRewards() external onlyOwner {
        uint256 unclaimedRewards = getUnclaimedIncentiveRewardsBalance();
        address[] memory _tokens = new address[](1);
        _tokens[0] = address(aToken);
        AaveIncentivesController.claimRewards(_tokens, unclaimedRewards, msg.sender); // claim directly to owner
        emit IncentivesClaimed(unclaimedRewards);
    }

    function getUnclaimedIncentiveRewardsBalance() public view returns (uint256) {
        return AaveIncentivesController.getUserUnclaimedRewards(address(this));
    }

    function balanceOfAToken() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function _getATokenAddress(address _asset) internal view returns (address) {
        DataTypes.ReserveData memory reserveData = AaveLendingPool.getReserveData(_asset);
        return reserveData.aTokenAddress;
    }

    // ===== VAULT ADMIN FUNCTIONS ===============

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryChanged(_treasury);
    }

    function setIncentiveController(address _aaveIncentivesController) external onlyOwner {
        require(_aaveIncentivesController != address(0), "Invalid address");
        AaveIncentivesController = IAaveIncentivesController(_aaveIncentivesController);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) public onlyOwner returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string("DevFund::executeTransaction: Transaction execution reverted."));
        return returnData;
    }

    receive() external payable {}
}
