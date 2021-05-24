import {DeployFunction} from 'hardhat-deploy/types';
import 'hardhat-deploy-ethers';
import 'hardhat-deploy';

const run: DeployFunction = async (hre) => {
  const {ethers, deployments, getNamedAccounts} = hre;
  const {deploy, execute} = deployments;
  const {creator} = await getNamedAccounts();

  const treasury = {address: '0x4a812C5EE699A40530eB49727E1818D43964324e'};
  const dollar = {address: '0xD86b5923F3AD7b585eD81B448170ae026c65ae9a'};
  const share = {address: '0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A'};
  const usdc = {address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'};
  const oracleCollateral = {address: '0x785808779131B0947F42b4b54537a4682EBEAB86'};

  await deploy('ZapPool', {
    contract: 'ZapPool',
    args: [],
    from: creator,
    log: true,
  });

  await execute(
    'ZapPool',
    {from: creator, log: true},
    'initialize',
    treasury.address,
    dollar.address,
    share.address,
    usdc.address,
    oracleCollateral.address
  );

  await execute(
    'ZapPool',
    {from: creator, log: true},
    'setRouter',
    '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506',
    [
      '0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
      '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270',
      '0xaaa5b9e6c589642f98a1cda99b9d024b8407285a',
    ]
  );
};

run.tags = ['matic', 'zap'];

run.skip = async (hre) => {
  return hre.network.name !== 'matic';
};
export default run;
