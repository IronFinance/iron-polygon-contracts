import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {ethers, deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const collateral = await deploy('MockCollateral', {
    from: creator,
    args: [creator, 'DAI', 18],
    log: true,
  });

  await deploy('Timelock', {
    from: creator,
    args: [creator, 12 * 60 * 60],
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
    'IRON Protocol Share',
    'STEEL',
    treasury.address,
    treasuryFund.address,
    creator,
    1620808447
  );

  const poolDAI = await deploy('PoolDAI', {
    contract: 'Pool',
    from: creator,
    args: [],
    log: true,
  });
  await execute(
    'PoolDAI',
    {from: creator, log: true},
    'initialize',
    dollar.address,
    share.address,
    collateral.address,
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
    collateral.address,
    treasuryPolicy.address,
    collateralRatioPolicy.address,
    collateralReserve.address,
    creator,
    creator
  );
  await execute('Treasury', {from: creator, log: true}, 'addPool', poolDAI.address);

  // ORACLES
  const mockPriceFeed_DAI_USD = await deploy('MockChainlinkAggregator_DAI_USD', {
    contract: 'MockChainlinkAggregator',
    args: ['100498532', 8],
    from: creator,
    log: true,
  });
  const mockPriceFeed_ETH_USD = await deploy('MockChainlinkAggregator_ETH_USD', {
    contract: 'MockChainlinkAggregator',
    args: ['4950000000', 8],
    from: creator,
    log: true,
  });
  const oracle_DOLLAR_BUSD = await deploy('PairOracle_DOLLAR_BUSD', {
    contract: 'MockPairOracle',
    args: [1003000],
    from: creator,
    log: true,
  });
  const oracle_SHARE_BNB = await deploy('PairOracle_SHARE_BNB', {
    contract: 'MockPairOracle',
    args: [20000],
    from: creator,
    log: true,
  });

  const oracleCollateral = await deploy('DaiOracle', {
    args: [mockPriceFeed_DAI_USD.address],
    from: creator,
    log: true,
  });

  const oracleDollar = await deploy('DollarOracle', {
    args: [dollar.address, oracle_DOLLAR_BUSD.address, oracleCollateral.address],
    from: creator,
    log: true,
  });

  const oracleShare = await deploy('ShareOracle', {
    args: [share.address, oracle_SHARE_BNB.address, mockPriceFeed_ETH_USD.address],
    from: creator,
    log: true,
  });

  await execute(
    'CollateralRatioPolicy',
    {from: creator, log: true},
    'setOracleDollar',
    oracleDollar.address
  );
  await execute('PoolDAI', {from: creator, log: true}, 'setOracle', oracleCollateral.address);
  await execute('Treasury', {from: creator, log: true}, 'setOracleDollar', oracleDollar.address);
  await execute('Treasury', {from: creator, log: true}, 'setOracleShare', oracleShare.address);
  await execute(
    'Treasury',
    {from: creator, log: true},
    'setOracleCollateral',
    oracleCollateral.address
  );
};

run.tags = ['mumbai'];

run.skip = async (hre) => {
  return hre.network.name !== 'mumbai';
};
export default run;
