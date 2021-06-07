// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasuryVault.sol";
import "../interfaces/IUniswapV2Router.sol";

contract VaultController is Ownable, Initializable {
    using SafeERC20 for IERC20;

    address public admin;
    address public collateralReserve;
    address private usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // usdc
    address private wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // wmatic
    ITreasuryVault public treasuryVault;

    uint256 private constant RATIO_PRECISION = 1000000; // 6 decimals
    uint256 private constant swapTimeout = 900; // 15 minutes
    uint256 public slippage = 20000; // 6 decimals
    address public router;
    address[] public swapPath;

    // events
    event AdminChanged(address indexed newAdmin);
    event TreasuryHarvested(address indexed incentive, uint256 amount);

    // modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner(), "Only admin or owner can trigger this function");
        _;
    }

    // constructor
    function initialize(
        address _treasuryVault,
        address _admin,
        address _collateralReserve
    ) external initializer onlyOwner {
        treasuryVault = ITreasuryVault(_treasuryVault);
        setAdmin(_admin);
        setCollateralReserve(_collateralReserve);
    }

    function claimIncentiveRewards() external onlyAdmin {
        require(collateralReserve != address(0), "No collateral reserve defined");
        treasuryVault.claimIncetiveRewards();
        // swap incentive to collateral
        uint256 _incentiveBalance = IERC20(wmatic).balanceOf(address(this));
        _swap(wmatic, usdc, _incentiveBalance);
        uint256 _collateralBalance = IERC20(usdc).balanceOf(address(this));
        IERC20(usdc).safeTransfer(collateralReserve, _collateralBalance);
        emit TreasuryHarvested(usdc, _collateralBalance);
    }

    function _swap(
        address _inputToken,
        address _outputToken,
        uint256 _inputAmount
    ) internal {
        if (_inputAmount == 0) {
            return;
        }
        require(router != address(0), "invalid route");
        require(swapPath[swapPath.length - 1] == _outputToken, "invalid path");
        IERC20(_inputToken).safeApprove(router, 0);
        IERC20(_inputToken).safeApprove(router, _inputAmount);

        IUniswapV2Router _swapRouter = IUniswapV2Router(router);
        uint256[] memory _amounts = _swapRouter.getAmountsOut(_inputAmount, swapPath);
        uint256 _minAmountOut = (_amounts[_amounts.length - 1] * (RATIO_PRECISION - slippage)) / RATIO_PRECISION;

        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _inputAmount,
            _minAmountOut,
            swapPath,
            address(this),
            block.timestamp + swapTimeout
        );
    }

    // ===== OWNERS FUNCTIONS ===============

    function setAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Invalid address");
        admin = _admin;
        emit AdminChanged(_admin);
    }

    function setSwapOptions(address _router, address[] calldata _path) public onlyOwner {
        require(_router != address(0), "Invalid address");
        require(_path.length > 1, "Invalid path");
        require(_path[0] == address(wmatic), "Path must start with wmatic");
        require(_path[_path.length - 1] == address(usdc), "Path must end with usdc");
        router = _router;
        swapPath = _path;
    }

    function setCollateralReserve(address _collateralReserve) public onlyOwner {
        require(_collateralReserve != address(0), "Invalid address");
        collateralReserve = _collateralReserve;
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
        require(success, string("VaultController::executeTransaction: Transaction execution reverted."));
        return returnData;
    }

    receive() external payable {}
}
