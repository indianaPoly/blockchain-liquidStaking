import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying ArbitrageBot with the account:", deployer.address);
  console.log(
    "Account balance:",
    await deployer.provider.getBalance(deployer.address)
  );

  const stbtc = await (await hre.ethers.getContractFactory("StBTC")).deploy();
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
