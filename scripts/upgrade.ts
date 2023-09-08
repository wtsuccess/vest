import { ethers, upgrades } from "hardhat";
import { TimedRelease__factory } from "../../typechain-types";

async function main() {
  const TimeRelease: TimedRelease__factory = await ethers.getContractFactory(
    "TimedRelease"
  );
  const timeRelease = await upgrades.upgradeProxy(
    "",
    TimeRelease
  );
  console.log("Contract Upgraded", await timeRelease.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
