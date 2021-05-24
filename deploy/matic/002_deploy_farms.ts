import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';
import {parseUnits} from '@ethersproject/units';
import {BigNumber} from 'ethers';

const run: DeployFunction = async (hre) => {
  const {ethers, deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const share = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};

  const lp_dollar_usdc = {address: '0x85dE135fF062Df790A5f20B79120f17D3da63b2d'};
  const lp_share_matic = {address: '0xA79983Daf2A92c2C902cD74217Efe3D8AF9Fba2a'};

  const numberOfBlocksPerDay = BigNumber.from((3600 * 24) / 2); // 2 seconds block time

  const masterChefFund = await deploy('MasterChefFund', {
    from: creator,
    log: true,
    args: [share.address],
  });

  const masterCheftTITAN = await deploy('MasterChef_TITAN', {
    contract: 'MasterChef',
    args: [
      share.address,
      masterChefFund.address,
      parseUnits('639270', 18).div(numberOfBlocksPerDay),
      14650975,
    ],
    from: creator,
    log: true,
  });
  await execute('MasterChefFund', {from: creator, log: true}, 'addPool', masterCheftTITAN.address);

  await execute(
    'MasterChef_TITAN',
    {from: creator, log: true},
    'add',
    300000,
    lp_share_matic.address,
    false
  );
  await execute(
    'MasterChef_TITAN',
    {from: creator, log: true},
    'add',
    700000,
    lp_dollar_usdc.address,
    false
  );
  await execute('MasterChef_TITAN', {from: creator, log: true}, 'massUpdatePools');
};

run.tags = ['matic', 'farms'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
