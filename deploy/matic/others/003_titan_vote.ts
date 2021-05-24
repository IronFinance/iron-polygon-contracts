import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();
  const titan = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};
  const govPool = {address: '0x08b5249F1fee6e4fCf8A7113943ed6796737386E'};

  await deploy('TitanVoteCount', {
    from: creator,
    log: true,
    args: [],
  });

  await execute(
    'TitanVoteCount',
    {from: creator, log: true},
    'initialize',
    titan.address,
    govPool.address
  );
};

run.tags = ['matic', 'titan-vote'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
