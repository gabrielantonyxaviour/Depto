const { ethers } = require("hardhat");
const verify = require("../helper-functions");
const {
  networkConfig,
  developmentChains,
  MIN_DELAY,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("--------------------------");
  log("Deploying TimeLock......");

  const timeLock = await deploy("TimeLock", {
    from: deployer,
    args: [MIN_DELAY, [], [], deployer],
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });

  log(`Deployed TimeLock at ${timeLock.address}`);

  if (!developmentChains.includes(network.name)) {
    await verify(timeLock.address, [MIN_DELAY, [], [], deployer]);
  }
};

module.exports.tags = ["all", "timelock"];
