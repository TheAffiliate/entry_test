const { expect } = require("chai");
const { ethers, network } = require("hardhat");

const ENTRY = ethers.parseEther("0.01");
const ONE_DAY = 24 * 60 * 60;

async function fastForwardOneDay() {
  await network.provider.send("evm_increaseTime", [ONE_DAY + 1]);
  await network.provider.send("evm_mine");
}

describe("PART B: self-written checks", function () {
  it("prevents a second payout after approval", async function () {
    const [employer, freelancer] = await ethers.getSigners();
    const board = await ethers.deployContract("FreelanceBountyBoard");
    await board.waitForDeployment();

    await board.connect(freelancer).registerFreelancer("solidity");
    await board.connect(employer).postBounty("Build a site", "solidity", { value: ethers.parseEther("1") });
    await board.connect(freelancer).applyForBounty(1);
    await board.connect(freelancer).submitWork(1, "https://example.com/submission");

    await board.connect(employer).approveAndPay(1, freelancer.address);

    await expect(board.connect(employer).approveAndPay(1, freelancer.address)).to.be.reverted;
  });

  it("tracks repeat entries and resets after a valid draw", async function () {
    const [owner, alice, bob, carol] = await ethers.getSigners();
    const raffle = await ethers.deployContract("DecentralisedRaffle");
    await raffle.waitForDeployment();

    await raffle.connect(alice).enterRaffle({ value: ENTRY });
    await raffle.connect(alice).enterRaffle({ value: ENTRY });
    await raffle.connect(bob).enterRaffle({ value: ENTRY });
    await raffle.connect(carol).enterRaffle({ value: ENTRY });

    expect(await raffle.getEntryCount(alice.address)).to.equal(2n);
    expect(await raffle.getPlayerCount()).to.equal(4n);
    expect(await raffle.getUniquePlayerCount()).to.equal(3n);

    await fastForwardOneDay();
    await raffle.connect(owner).selectWinner();

    expect(await raffle.getPlayerCount()).to.equal(0n);
    expect(await raffle.getUniquePlayerCount()).to.equal(0n);
    expect(await raffle.getPot()).to.equal(0n);
  });
});
