import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying account:", deployer.address);
  console.log(
    "Account balance:",
    await deployer.provider.getBalance(deployer.address)
  );

  const stbtc = await (
    await hre.ethers.getContractFactory("MockERC20")
  ).deploy("Mock WBTC", "WBTC", 1000);

  console.log(
    "stbtc가 정상적으로 배포가 되었습니다.",
    await stbtc.getAddress()
  );
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.log(err);
    process.exit(1);
  });
