const { ethers } = require("hardhat");
const verify = require("../helper-functions");
const {
  networkConfig,
  developmentChains,
  QUORUM_PERCENTAGE,
  VOTING_PERIOD,
  VOTING_DELAY,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("--------------------------");
  const depToken = await deployments.get("DepToken");
  const timeLock = await deployments.get("TimeLock");
  const args = [
    depToken.address,
    timeLock.address,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  ];
  log("Deploying Governor Contract.....");

  const governor = await deploy("GovernorContract", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
  log(`Deployed Governor Contract at ${governor.address}`);

  if (!developmentChains.includes(network.name)) {
    await verify(governor.address, args);
  }
};
module.exports.tags = ["all", "governor"];
