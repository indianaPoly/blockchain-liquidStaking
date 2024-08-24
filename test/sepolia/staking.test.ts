import hre from "hardhat";
import { BaseContract, ContractFactory } from "ethers";
import { MockERC20, Staking, StBTC } from "../../typechain-types";

describe("staking", () => {
  let WBTC: ContractFactory, wbtc: MockERC20;
  let StBTC: ContractFactory, stbtc: StBTC;
  let Staking: ContractFactory, staking: Staking;
  let owner: any, addr1: any, addr2: any;

  beforeEach(async () => {
    [owner, addr1, addr2] = await hre.ethers.getSigners();

    // create contract
    // 인자로 들어가는 값은 contract 이름과 동일해야 함.
    WBTC = await hre.ethers.getContractFactory("MockERC20");
    StBTC = await hre.ethers.getContractFactory("StBTC");
    Staking = await hre.ethers.getContractFactory("Staking");

    // create instance
    // contract 초기 생성자에 맞게 지정하고 배포를 진행
    wbtc = (await WBTC.deploy("Mock WBTC", "WBTC", 1000, {
      gasLimit: 400000,
    })) as MockERC20;
    await wbtc.waitForDeployment();
    console.log("successful deploy wbtc");

    stbtc = (await StBTC.deploy({
      gasLimit: 400000,
    })) as StBTC;
    await stbtc.waitForDeployment();
    console.log("sucessful deploy stbtc");

    const wbtcAddress = await wbtc.getAddress();
    const stbtcAddress = await stbtc.getAddress();
    staking = (await Staking.deploy(wbtcAddress, stbtcAddress, {
      gasLimit: 400000,
    })) as Staking;
    await staking.waitForDeployment();
    console.log("successful deploy staking contract");

    // transfer
    await wbtc.transfer(addr1.address, hre.ethers.parseUnits("50", 6));
    console.log("addr1 사용자에게 50개 전송하였음");

    const stakingAddress = await staking.getAddress();
    // approve
    await wbtc
      .connect(addr1)
      .approve(stakingAddress, hre.ethers.parseUnits("100", 6));

    await stbtc
      .connect(addr1)
      .approve(stakingAddress, hre.ethers.parseUnits("100", 6));

    console.log("init setting finish");
  });

  it("Should allow a user to stake WBTC and receive StBTC", async () => {
    let addr1Value, stakingValue, stbtcValue;

    addr1Value = await wbtc.balanceOf(addr1.address);
    console.log(`사용자가 처음에 가지고 있는 금액: ${addr1Value}`);

    const allowance = await wbtc.allowance(addr1.address, staking.getAddress());
    console.log(`staking 계약에 대한 승인 금액: ${allowance}`);

    const stakeAmount = hre.ethers.parseUnits("0.01", 6);
    console.log(`staking 하는 금액 : ${stakeAmount}`);

    console.log("");
    console.log("");
    console.log("---------------staking 실행 중-------------------");
    console.log("");
    console.log("");
    // Approve staking contract to spend WBTC
    // Stake WBTC
    await staking.connect(addr1).stake(stakeAmount);
    // Check StBTC balance
    stakingValue = await staking.getStakingAmount(addr1.address);
    console.log(`실제 staking 된 금액 : ${stakingValue}`);

    stbtcValue = await stbtc.balanceOf(addr1.address);
    console.log(`가지고 있는 StBTC : ${stbtcValue}`);

    addr1Value = await wbtc.balanceOf(addr1.address);
    console.log(`전송 이후 금액: ${addr1Value}`);

    console.log("");
    console.log("");
    console.log("---------------출금 실행 중-------------------");
    console.log("");
    console.log("");

    await staking.connect(addr1).unstake(hre.ethers.parseUnits("0.001", 6));

    stakingValue = await staking.getStakingAmount(addr1.address);
    console.log(`실제 staking 된 금액 : ${stakingValue}`);

    stbtcValue = await stbtc.balanceOf(addr1.address);
    console.log(`가지고 있는 StBTC : ${stbtcValue}`);

    addr1Value = await wbtc.balanceOf(addr1.address);
    console.log(`출금 이후 금액: ${addr1Value}`);
  });
});
