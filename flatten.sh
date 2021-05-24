#!/bin/bash

# npx hardhat flatten ./contracts/CollateralRatioPolicy.sol 2>&1 | tee ./flattens/CollateralRatioPolicy_flatten.sol
# npx hardhat flatten ./contracts/CollateralReserve.sol 2>&1 | tee ./flattens/CollateralReserve_flatten.sol
# npx hardhat flatten ./contracts/oracle/CollateralOracle.sol 2>&1 | tee ./flattens/CollateralOracle_flatten.sol
# npx hardhat flatten ./contracts/Dollar.sol 2>&1 | tee ./flattens/Dollar_flatten.sol
# npx hardhat flatten ./contracts/oracle/DollarOracle.sol 2>&1 | tee ./flattens/DollarOracle_flatten.sol
# npx hardhat flatten ./contracts/_mock/collateral/MockCollateral.sol 2>&1 | tee ./flattens/MockCollateral_flatten.sol
# npx hardhat flatten ./contracts/MasterChefFund.sol 2>&1 | tee ./flattens/MasterChefFund_flatten.sol
# npx hardhat flatten ./contracts/ConsolidatedFund.sol 2>&1 | tee ./flattens/ConsolidatedFund_flatten.sol
# npx hardhat flatten ./contracts/MasterChef.sol 2>&1 | tee ./flattens/MasterChef_flatten.sol
# npx hardhat flatten ./contracts/libs/SpotPriceGetter.sol 2>&1 | tee ./flattens/SpotPriceGetter_flatten.sol
# npx hardhat flatten ./contracts/ZapPool.sol 2>&1 | tee ./flattens/ZapPool_flatten.sol
# npx hardhat flatten ./contracts/oracle/PcsPairOracle.sol 2>&1 | tee ./flattens/PcsPairOracle_flatten.sol
# npx hardhat flatten ./contracts/_mock/oracle/MockPairOracle.sol 2>&1 | tee ./flattens/PairOracle_flatten.sol
# npx hardhat flatten ./contracts/Pool.sol 2>&1 | tee ./flattens/Pool_flatten.sol
# npx hardhat flatten ./contracts/Share.sol 2>&1 | tee ./flattens/Share_flatten.sol
# npx hardhat flatten ./contracts/oracle/ShareOracle.sol 2>&1 | tee ./flattens/ShareOracle_flatten.sol
# npx hardhat flatten ./contracts/Timelock.sol 2>&1 | tee ./flattens/Timelock_flatten.sol
# npx hardhat flatten ./contracts/Treasury.sol 2>&1 | tee ./flattens/Treasury_flatten.sol
# npx hardhat flatten ./contracts/TreasuryFund.sol 2>&1 | tee ./flattens/TreasuryFund_flatten.sol
# npx hardhat flatten ./contracts/TreasuryPolicy.sol 2>&1 | tee ./flattens/TreasuryPolicy_flatten.sol

# npx hardhat flatten ./contracts/vaults/aave/TreasuryVaultAave.sol 2>&1 | tee ./flattens/TreasuryVaultAave_flatten.sol
# npx hardhat flatten ./contracts/vaults/TreasuryVaultTest.sol 2>&1 | tee ./flattens/TreasuryVaultTest_flatten.sol

npx hardhat flatten ./contracts/TitanVoteCount.sol 2>&1 | tee ./flattens/TitanVoteCount_flatten.sol
