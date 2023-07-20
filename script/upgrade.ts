import { upgrades, ethers } from "hardhat";

const PROXY = "0x22f68ab2f53e4eb0f8797cd5050950c42ab6ae4c";

const main = async () => {
  const StakingV2Factory = await ethers.getContractFactory("StakingV2");
  const stakingV2 = await upgrades.upgradeProxy(PROXY, StakingV2Factory);

  await stakingV2.waitForDeployment();

  console.log(`The Implementation has been upgraded`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
