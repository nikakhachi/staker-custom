import { upgrades, ethers } from "hardhat";

const main = async () => {
  const TokenFactory = await ethers.getContractFactory("Token");
  const token = await TokenFactory.deploy("Test Token", "TST", ethers.parseEther("1000000"));

  await token.waitForDeployment();

  const tokenAddress = await token.getAddress();

  console.log(`Token Deployed on Address: ${tokenAddress}`);

  const StakingFactory = await ethers.getContractFactory("Staking");
  const staking = await upgrades.deployProxy(StakingFactory, [tokenAddress, false, false], { kind: "uups" });

  await token.waitForDeployment();

  const stakingAddress = await staking.getAddress();

  console.log(`Staking Deployed on Address: ${stakingAddress}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
