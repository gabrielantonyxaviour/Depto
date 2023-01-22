const { ethers } = require("hardhat");
const verify = require("../helper-functions");
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
module.exports = async function ({ getNamedAccounts, deployments, network }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("-----------------------------");
  log("Deploying DepToken.........");

  const depToken = await deploy("DepToken", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });

  log(`GovernanceToken deployed at ${depToken.address}`);

  if (!developmentChains.includes(network.name)) {
    await verify(depToken.address, []);
  }

  log(`Delegating to deployer`);

  await delegate(depToken.address, deployer);
  log("Delegated!");
};

const delegate = async function (governanceTokenAddress, delegatedAccount) {
  const governanceToken = await ethers.getContractAt(
    "DepToken",
    governanceTokenAddress
  );
  const transactionResponse = await governanceToken.delegate(delegatedAccount);
  await transactionResponse.wait(1);
  console.log(
    `Checkpoints: ${await governanceToken.numCheckpoints(delegatedAccount)}`
  );
};

module.exports.tags = ["all", "governor"];
