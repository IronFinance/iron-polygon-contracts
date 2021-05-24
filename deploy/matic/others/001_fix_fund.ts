import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const fund = await deploy('ConsolidatedFund', {
    from: creator,
    log: true,
    args: [],
  });
};

run.tags = ['matic', 'fix-fund'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
