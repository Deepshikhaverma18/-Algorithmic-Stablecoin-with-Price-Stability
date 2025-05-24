async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  const Stablecoin = await ethers.getContractFactory("AlgorithmicStablecoin");

  // Replace with actual deployed oracle address or mock
  const oracleAddress = "0x0000000000000000000000000000000000000000";

  const stablecoin = await Stablecoin.deploy(
    "AlgoStablecoin",
    "ASTBL",
    oracleAddress,
    ethers.utils.parseUnits("1", 18), // targetPrice = 1.0
    100 // adjustmentFactor = 1%
  );

  await stablecoin.deployed();

  console.log("AlgorithmicStablecoin deployed to:", stablecoin.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
