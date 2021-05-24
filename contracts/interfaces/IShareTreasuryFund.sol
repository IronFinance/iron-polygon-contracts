// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IShareTreasuryFund {
    function claimTreasuryFundRewards() external;

    function unclaimedTreasuryFund() external view returns (uint256 _pending);

    function setTreasuryFund(address _treasuryFund) external;
}
