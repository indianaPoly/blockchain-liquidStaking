import hre from "hardhat";

async function main() {
  const wbtcAddress = "";
  const stbtcAddress = "";

  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying account:", deployer.address);
  console.log(
    "Account balance:",
    await deployer.provider.getBalance(deployer.address)
  );

  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = Staking.deploy(wbtcAddress, stbtcAddress);
  (await staking).waitForDeployment();

  console.log("staking 컨트랙트가 정상적으로 배포가 되었습니다.");
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.log(err);
    process.exit(1);
  });
