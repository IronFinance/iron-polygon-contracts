import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';
import {parseUnits} from '@ethersproject/units';
import {BigNumber} from 'ethers';

const run: DeployFunction = async (hre) => {
  const {ethers, deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const usdc = {address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'};
  const share = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};
  const lp_share_dollar = {address: '0x35c1895DAC1e2432b320e2927b4F71a0D995602F'};

  const numberOfBlocksPerDay = BigNumber.from((3600 * 24) / 2); // 2 seconds block time

  const fund = await deploy('ConsolidatedFund', {
    from: creator,
    log: true,
    args: [],
  });

  const masterCheftTITAN = await deploy('MasterChefSingle_TITAN', {
    contract: 'MasterChef',
    args: [
      share.address,
      fund.address,
      parseUnits('95890', 18).div(numberOfBlocksPerDay),
      14761081,
    ],
    from: creator,
    log: true,
  });
  await execute(
    'ConsolidatedFund',
    {from: creator, log: true},
    'addPool',
    masterCheftTITAN.address,
    share.address
  );
  await execute(
    'MasterChefSingle_TITAN',
    {from: creator, log: true},
    'add',
    100000,
    share.address,
    false
  );

  const masterChefUSDC = await deploy('MasterChef_USDC', {
    contract: 'MasterChef',
    args: [usdc.address, fund.address, parseUnits('10000', 6).div(numberOfBlocksPerDay), 14761081],
    from: creator,
    log: true,
  });
  await execute(
    'ConsolidatedFund',
    {from: creator, log: true},
    'addPool',
    masterChefUSDC.address,
    usdc.address
  );
  await execute(
    'MasterChef_USDC',
    {from: creator, log: true},
    'add',
    100000,
    lp_share_dollar.address,
    false
  );
};

run.tags = ['matic', 'farms-v2'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
