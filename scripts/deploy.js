// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
  const V1Contract = await ethers.getContractFactory("BotV1");
  console.log("Deploying V1Contract...");
  const tokenContract = "0x8BEc47865aDe3B172A928df8f990Bc7f2A3b9f79";
  const withdrawFee = 3;
  const v1Contract = await upgrades.deployProxy(
    V1Contract,
    [tokenContract, withdrawFee],
    {
      initializer: "initialize",
    }
  );

  await v1Contract.deployed();

  console.log("V1 Contract Deployed to:", v1Contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
