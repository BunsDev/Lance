const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Bid Token contract", function () {
  it("All addresses should have desired amounts", async function () {
    const [signer1, signer2, signer3] = await ethers.getSigners();
    const bidToken = await ethers.deployContract("BidToken", [
      signer1.address,
      signer2.address,
      signer3.address,
    ]);

    const signer1Balance = await bidToken.balanceOf(signer1.address);
    const signer2Balance = await bidToken.balanceOf(signer2.address);
    const signer3Balance = await bidToken.balanceOf(signer3.address);
    expect(signer1Balance).to.equal(30);
    expect(signer2Balance).to.equal(10);
    expect(signer3Balance).to.equal(20);
  });
});
