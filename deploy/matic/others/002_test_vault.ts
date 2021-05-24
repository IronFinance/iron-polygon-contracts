import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();
  const usdc = {address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'};
  const aaveLendingPool = {address: '0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf'};
  const aaveIncetiveController = {address: '0x357D51124f59836DeD84c8a1730D72B749d8BC23'};

  const treasuryVaultProxy = await deploy('TreasuryVaultTest', {
    from: creator,
    log: true,
    args: [],
  });

  const treasuryVaultAave = await deploy('TreasuryVaultAave', {
    from: creator,
    log: true,
    args: [],
  });

  await execute(
    'TreasuryVaultTest',
    {from: creator, log: true},
    'initialize',
    usdc.address,
    treasuryVaultAave.address
  );

  await execute(
    'TreasuryVaultAave',
    {from: creator, log: true},
    'initialize',
    usdc.address,
    treasuryVaultProxy.address,
    aaveLendingPool.address,
    aaveIncetiveController.address
  );
};

run.tags = ['matic', 'test-vault'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
