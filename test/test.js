const { expect } = require("chai");
const { ethers } = require("hardhat");

let getBlindedBid;
let secret;
let vickeryAuction;
let bidToken;
let evaluatorContract;
let lanceToken;
let signer1, signer2, signer3;
let evaluationContract;

describe("Bid Token contract", function () {
  it("All addresses should have desired amounts", async function () {
    const [signer1, signer2, signer3] = await ethers.getSigners();
    bidToken = await ethers.deployContract("BidToken", [
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

describe("GetBlindedBid", async function () {
  it("BlindedBid should produce a bytes32 something", async function () {
    const [signer1] = await ethers.getSigners();
    getBlindedBid = await ethers.deployContract("GetBlindedBid");
    secret = {
      text: "lxytz",
      byte32Text:
        "0x6c7879747a000000000000000000000000000000000000000000000000000000",
    };
    const blindedBid = await getBlindedBid.getBlindedBid(30, secret.byte32Text);
    // console.log(blindedBid);
    expect(blindedBid).to.have.lengthOf(66);
  });
});

describe("Vickery Auction", async function () {
  it("Vickery Auction deploys", async function () {
    vickeryAuction = await ethers.deployContract("BlindAuction", [
      180,
      180,
      bidToken.getAddress(),
    ]);
  });

  it("Bidders allowance increased successfully", async function () {
    [signer1, signer2, signer3] = await ethers.getSigners();
    const auctionAddress = vickeryAuction.getAddress();
    await bidToken.connect(signer1).approve(auctionAddress, 30);
    await bidToken.connect(signer2).approve(auctionAddress, 10);
    await bidToken.connect(signer3).approve(auctionAddress, 20);

    expect(
      await bidToken.allowance(signer1.address, auctionAddress)
    ).to.be.equal(30);
    expect(
      await bidToken.allowance(signer2.address, auctionAddress)
    ).to.be.equal(10);
    expect(
      await bidToken.allowance(signer3.address, auctionAddress)
    ).to.be.equal(20);
  });

  it("Amounts should be deducted when bid is sent", async function () {
    const blindedBid10 = await getBlindedBid.getBlindedBid(
      10,
      secret.byte32Text
    );
    const blindedBid20 = await getBlindedBid.getBlindedBid(
      20,
      secret.byte32Text
    );
    const blindedBid30 = await getBlindedBid.getBlindedBid(
      30,
      secret.byte32Text
    );

    await vickeryAuction.bid(signer1.address, 30, blindedBid30);
    await vickeryAuction.bid(signer2.address, 10, blindedBid10);
    await vickeryAuction.bid(signer3.address, 20, blindedBid20);

    expect(await bidToken.balanceOf(signer1.address)).to.be.equal(0);
    expect(await bidToken.balanceOf(signer2.address)).to.be.equal(0);
    expect(await bidToken.balanceOf(signer3.address)).to.be.equal(0);
  });

  it("The winner of the auction should pay the second highest bid", async function () {
    await vickeryAuction.reveal([30], [secret.byte32Text], signer1.address);
    await vickeryAuction.reveal([10], [secret.byte32Text], signer2.address);
    await vickeryAuction.reveal([20], [secret.byte32Text], signer3.address);
    await vickeryAuction.auctionEnd();
    expect(await bidToken.balanceOf(signer1.address)).to.be.equal(10);
    expect(await bidToken.balanceOf(signer2.address)).to.be.equal(10);
    expect(await bidToken.balanceOf(signer3.address)).to.be.equal(20);
  });

  it("The Auction contract should hold the second highest bid", async function () {
    const contractBalance = await bidToken.balanceOf(
      await vickeryAuction.getAddress()
    );
    expect(contractBalance).to.be.equal(20);
  });
});

describe("Lance Token", async function () {
  it("Should deploy", async () => {
    lanceToken = await ethers.deployContract("LanceToken", [
      signer1.address,
      signer2.address,
      signer3.address,
    ]);
  });
});

describe("Evaluator Contract", async function () {
  it("Should deploy", async () => {
    evaluatorContract = await ethers.deployContract("EvaluatorContract", [
      await lanceToken.getAddress(),
      10,
    ]);
  });
  it("should increase lance allowance successfully", async function () {
    [signer1, signer2, signer3] = await ethers.getSigners();
    const evaluatorAddress = evaluatorContract.getAddress();
    await lanceToken.connect(signer1).approve(evaluatorAddress, 30);
    await lanceToken.connect(signer2).approve(evaluatorAddress, 10);
    await lanceToken.connect(signer3).approve(evaluatorAddress, 20);

    expect(
      await lanceToken.allowance(signer1.address, evaluatorAddress)
    ).to.be.equal(30);
    expect(
      await lanceToken.allowance(signer2.address, evaluatorAddress)
    ).to.be.equal(10);
    expect(
      await lanceToken.allowance(signer3.address, evaluatorAddress)
    ).to.be.equal(20);
  });

  it("should add evaluators", async () => {
    await evaluatorContract.addEvaluator(signer1.address, "ipfs1");
    await evaluatorContract.addEvaluator(signer2.address, "ipfs2");
    await evaluatorContract.addEvaluator(signer3.address, "ipfs3");
    const evaluators = await evaluatorContract.getEvaluators();
    expect(evaluators.length).to.be.equal(3);
  });

  it("should increment stake", async () => {
    await evaluatorContract.increaseStake(signer3.address, 10);
    const evaluators_ = await evaluatorContract.getEvaluators();
    expect(evaluators_[2][1]).to.be.equal(20);
  });

  it("should decrement stake", async () => {
    await evaluatorContract.decreaseStake(signer3.address, 10);
    const evaluators_ = await evaluatorContract.getEvaluators();
    expect(evaluators_[2][1]).to.be.equal(10);
  });

  // it("should remove evaluators", async () => {
  //   expect(await lanceToken.balanceOf(signer1.address)).to.be.equal(20);
  //   await evaluatorContract.removeEvaluator(signer1.address);
  //   const evaluatorRemoved = await evaluatorContract.checkEvaluatorRemoved(
  //     signer1.address
  //   );
  //   // console.log(evaluatorRemoved);
  //   expect(evaluatorRemoved).to.be.equal(true);
  //   expect(await lanceToken.balanceOf(signer1.address)).to.be.equal(30);
  // });

  it("subbract tests", async () => {
    // console.log("Difference: ", await getBlindedBid.subract(1, 2));
  });
});

describe("Evaluation Contract", async function () {
  it("should populate evaluators", async () => {
    evaluationContract = await ethers.deployContract("Evaluation", [
      await evaluatorContract.getAddress(),
      await lanceToken.getAddress(),
      await bidToken.getAddress(),
      50,
    ]);
    await evaluationContract.populateEvaluators(1, 3);
    const selectedEvaluators = await evaluationContract.getEvaluators();
    expect(selectedEvaluators.length).to.be.equal(3);
    // console.log(selectedEvaluators);

    await evaluationContract.evaluate();
  });
});
