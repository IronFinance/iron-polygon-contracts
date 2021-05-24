import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {ethers, deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const wmatic = {address: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270'};
  const usdc = {address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'};
  const dollar = {address: '0xD86b5923F3AD7b585eD81B448170ae026c65ae9a'};
  const share = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};

  const lp_dollar_usdc = {address: '0x85dE135fF062Df790A5f20B79120f17D3da63b2d'};
  const lp_share_matic = {address: '0xA79983Daf2A92c2C902cD74217Efe3D8AF9Fba2a'};

  // ORACLES
  const priceFeed_USDC_USD = {address: '0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7'};
  const priceFeed_MATIC_USD = {address: '0xAB594600376Ec9fD91F8e885dADF0CE036862dE0'};
  const oracle_DOLLAR_USDC = await deploy('PairOracle_DOLLAR_USDC', {
    contract: 'PcsPairOracle',
    args: [lp_dollar_usdc.address],
    from: creator,
    log: true,
  });

  const oracle_SHARE_MATIC = await deploy('PairOracle_SHARE_MATIC', {
    contract: 'PcsPairOracle',
    args: [lp_share_matic.address],
    from: creator,
    log: true,
  });

  const oracleCollateral = await deploy('CollateralOracle', {
    args: [priceFeed_USDC_USD.address],
    from: creator,
    log: true,
  });

  const oracleDollar = await deploy('DollarOracle', {
    args: [dollar.address, oracle_DOLLAR_USDC.address, oracleCollateral.address, 12],
    from: creator,
    log: true,
  });

  const oracleShare = await deploy('ShareOracle', {
    args: [share.address, oracle_SHARE_MATIC.address, priceFeed_MATIC_USD.address],
    from: creator,
    log: true,
  });

  await execute(
    'CollateralRatioPolicy',
    {from: creator, log: true},
    'setOracleDollar',
    oracleDollar.address
  );
  await execute('PoolUSDC', {from: creator, log: true}, 'setOracle', oracleCollateral.address);
  await execute('Treasury', {from: creator, log: true}, 'setOracleDollar', oracleDollar.address);
  await execute('Treasury', {from: creator, log: true}, 'setOracleShare', oracleShare.address);
  await execute(
    'Treasury',
    {from: creator, log: true},
    'setOracleCollateral',
    oracleCollateral.address
  );
};

run.tags = ['matic', 'oracles'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
