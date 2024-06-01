const hre = require("hardhat");

async function main() {
  const LanceToken = await hre.ethers.getContractFactory("LanceToken");
  const lanceToken = await LanceToken.deploy(
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  );

  console.log("LanceToken deployed to:", await lanceToken.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
