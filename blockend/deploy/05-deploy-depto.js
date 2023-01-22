const { ethers } = require("hardhat");
const verify = require("../helper-functions");
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------");

  log("Deploying Depto...............");
  const depto = await deploy("Depto", {
    from: deployer,
    args: [],

    log: true,
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });

  log(`Deployed Depto at ${depto.address}`);

  if (!developmentChains.includes(network.name)) {
    await verify(depto.address, []);
  }

  const deptoContract = await ethers.getContract("Depto", deployer);
  const timelock = await deployments.get("TimeLock");
  const transfetx = await deptoContract.transferOwnership(timelock.address);
  await transfetx.wait(1);
  log("Ownership of Depto transferred to DAO");
};

module.exports.tag = ["all", "depto"];
