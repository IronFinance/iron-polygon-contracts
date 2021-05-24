// SPDX-License-Identifier: MITT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasuryVault.sol";

contract TreasuryVaultTest is Ownable, Initializable {
    using SafeERC20 for IERC20;

    IERC20 public asset;
    ITreasuryVault public treasuryVault;

    // Constructor

    function initialize(address _asset, address _treasuryVault) external initializer onlyOwner {
        asset = IERC20(_asset);
        treasuryVault = ITreasuryVault(_treasuryVault);
    }

    function deposit() external onlyOwner {
        uint256 _amount = asset.balanceOf(address(this));
        require(_amount > 0, "amount = 0");
        asset.safeApprove(address(treasuryVault), _amount);
        treasuryVault.deposit(_amount);
    }

    function withdraw() external onlyOwner {
        treasuryVault.withdraw();
    }

    function balance() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function withdrawAsset() external onlyOwner {
        asset.safeTransfer(msg.sender, asset.balanceOf(address(this)));
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
