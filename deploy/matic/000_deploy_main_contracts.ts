import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  console.log('Deploy main contracts');

  const usdc = {address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'};

  await deploy('Timelock', {
    from: creator,
    args: [creator, 12 * 60 * 60],
    log: true,
  });

  await deploy('Multicall', {
    args: [],
    from: creator,
    log: true,
  });

  const treasury = await deploy('Treasury', {
    from: creator,
    log: true,
    args: [],
  });

  const treasuryPolicy = await deploy('TreasuryPolicy', {
    from: creator,
    log: true,
    args: [],
  });
  await execute(
    'TreasuryPolicy',
    {from: creator, log: true},
    'initialize',
    treasury.address,
    1000,
    4000,
    150000
  );

  const collateralRatioPolicy = await deploy('CollateralRatioPolicy', {
    from: creator,
    log: true,
    args: [],
  });

  const collateralReserve = await deploy('CollateralReserve', {
    from: creator,
    log: true,
    args: [],
  });
  await execute('CollateralReserve', {from: creator, log: true}, 'initialize', treasury.address);

  const treasuryFund = await deploy('TreasuryFund', {
    from: creator,
    log: true,
    args: [],
  });

  const dollar = await deploy('Dollar', {
    from: creator,
    args: [],
    log: true,
  });
  await execute(
    'Dollar',
    {from: creator, log: true},
    'initialize',
    'IRON Stablecoin',
    'IRON',
    treasury.address
  );

  const share = await deploy('Share', {
    from: creator,
    args: [],
    log: true,
  });
  await execute(
    'Share',
    {from: creator, log: true},
    'initialize',
    'IRON Titanium Token',
    'TITAN',
    treasury.address,
    treasuryFund.address,
    creator,
    1621346400
  );

  const poolUSDC = await deploy('PoolUSDC', {
    contract: 'Pool',
    from: creator,
    args: [],
    log: true,
  });
  await execute(
    'PoolUSDC',
    {from: creator, log: true},
    'initialize',
    dollar.address,
    share.address,
    usdc.address,
    treasury.address
  );

  await execute('TreasuryFund', {from: creator, log: true}, 'initialize', share.address);
  await execute(
    'CollateralRatioPolicy',
    {from: creator, log: true},
    'initialize',
    treasury.address,
    dollar.address
  );

  await execute(
    'Treasury',
    {from: creator, log: true},
    'initialize',
    dollar.address,
    share.address,
    usdc.address,
    treasuryPolicy.address,
    collateralRatioPolicy.address,
    collateralReserve.address,
    creator,
    creator
  );
  await execute('Treasury', {from: creator, log: true}, 'addPool', poolUSDC.address);
};

run.tags = ['matic', 'main'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
