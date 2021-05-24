import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();
  const share = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};

  await deploy('TreasuryFund', {
    from: creator,
    log: true,
    args: [],
  });

  await execute('TreasuryFund', {from: creator, log: true}, 'initialize', share.address);
};

run.tags = ['matic', 'fix_treasury_fund'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
