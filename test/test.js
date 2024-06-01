// //Utils
// function getIQR(arr) {
//   let upperHalf = getUpperHalf(arr.sort());
//   let lowerHalf = getLowerHalf(arr.sort());
//   let q3 = getMedian(upperHalf);
//   let q1 = getMedian(lowerHalf);
//   let IQR = q3 - q1;
//   let upperIQR = q3 + (IQR * 3) / 2;
//   let lowerIQR;
//   if (q1 < (IQR * 3) / 2) {
//     lowerIQR = 0;
//   } else {
//     lowerIQR = q1 - (IQR * 3) / 2;
//   }
//   return [upperIQR, lowerIQR];
// }

// function getPunishmentStake(totalPunishable, average, actual, previousStake) {
//   return (
//     previousStake -
//     (totalPunishable * (Math.abs(average - actual) / actual)) / 2
//   );
// }

// function getMean(arr) {
//   let total = 0;
//   for (let i = 0; i < arr.length; i++) {
//     total = total + arr[i];
//   }
//   return Math.floor(total / arr.length);
// }

// function getMedian(array_) {
//   const array = array_.sort();
//   if (array.length == 0) {
//     return 0;
//   }
//   if (array.length % 2 == 0) {
//     let medianIndice1 = Math.floor(array.length / 2);
//     let medianIndice2 = medianIndice1 - 1;
//     let median1 = array[medianIndice1];
//     let median2 = array[medianIndice2];
//     return Math.floor((median1 + median2) / 2);
//   } else {
//     let medianIndex = Math.floor(array.length / 2);
//     return array[medianIndex];
//   }
// }

// function getUpperHalf(arr) {
//   let arrLength = Math.floor(arr.length / 2);
//   let upperHalf = [];
//   if (arr.length % 2 == 0) {
//     for (let i = arrLength; i < arr.length; i++) {
//       upperHalf[i - arrLength] = arr[i];
//     }
//     return upperHalf;
//   } else {
//     for (let i = arrLength + 1; i < arr.length; i++) {
//       upperHalf[i - arrLength - 1] = arr[i];
//     }
//     return upperHalf;
//   }
// }

// function getLowerHalf(arr) {
//   let arrLength = Math.floor(arr.length / 2);
//   let lowerHalf = [];
//   for (let i = 0; i < arrLength; i++) {
//     lowerHalf[i] = arr[i];
//   }
//   return lowerHalf;
// }

// function getRewards(arrShares, tokens) {
//   let totalShares = 0;
//   for (let share of arrShares) {
//     totalShares = share + totalShares;
//   }
//   const distributionArray = [];
//   for (let i = 0; i < arrShares.length; i++) {
//     distributionArray[i] = Math.floor((arrShares[i] / totalShares) * tokens);
//   }
//   return distributionArray;
// }

// function getOverallScore(algoMean, heursiticMean, ownerScore) {
//   return (algoMean * 0.6 + heursiticMean * 0.4) * 0.7 + ownerScore * 0.3;
// }

// function getShares(array, median, medianScore, notMedianScore, lower, upper) {
//   return array.map((el) => {
//     if (el == median) {
//       return medianScore;
//     } else if (el > lower && el <= upper) {
//       return notMedianScore;
//     } else {
//       return 0;
//     }
//   });
// }

// function sumArray(arr, arr1) {
//   if (arr == arr1) return "Arrays arent equal";
//   let newArr = [];
//   for (let i = 0; i < arr.length; i++) {
//     newArr[i] = arr[i] + arr1[i];
//   }
//   return newArr;
// }

// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// let getBlindedBid;
// let secret;
// let vickeryAuction;
// let bidToken;
// let evaluatorContract;
// let lanceToken;
// let signer1, signer2, signer3;
// let evaluationContract;

// let signers;
// let decimals = 100000;
// let evaluatorLength = 15;
// let ownerScore = 100;
// let heuristicScores = [90, 90, 90, 70, 70, 70, 80, 80, 80, 80];
// let algoScores = [90, 90, 90, 90, 90, 90, 90, 90, 90, 90];
// let heuristicMedian = getMedian(heuristicScores);
// let heuristicMean = getMean(heuristicScores);
// let [heuristicIQRUpper, heuristicIQRLower] = getIQR(heuristicScores);
// let algoMedian = getMedian(algoScores);
// let algoMean = getMean(algoScores);
// let [algoIQRUpper, algoIQRLower] = getIQR(algoScores);
// let overallScore = getOverallScore(algoMean, heuristicMean, ownerScore);
// let MedianShares = 70;
// let NonMedianShares = 30;
// let heuristicAllocation = 40;
// let evaluatorAllocation = 70;
// let fees = 100;
// // let totalPunishable = 10;
// // let newPunishedStakeHeuristic = getPunishmentStake(
// //   10,
// //   heuristicScores[heuristicScores.length - 1],
// //   heursiticMean,
// //   10
// // );
// // let newPunishedAlgorithmic = getPunishmentStake(
// //   10,
// //   algoScores[algoScores.length - 1],
// //   algoMean,
// //   newPunishedStakeHeuristic
// // );
// let sharesHeuristic = getShares(
//   heuristicScores,
//   heuristicMedian,
//   MedianShares,
//   NonMedianShares,
//   heuristicIQRLower,
//   heuristicIQRUpper
// );

// let sharesAlgo = getShares(
//   algoScores,
//   algoMedian,
//   MedianShares,
//   NonMedianShares,
//   algoIQRLower,
//   algoIQRUpper
// );

// let totalShares = sumArray(sharesHeuristic, sharesAlgo);
// let balances = getRewards(sharesAlgo, 100 * decimals);

// const addEvaluators = async (numberOfSigners, evaluatorContract) => {
//   for (let i = 4; i <= numberOfSigners; i++) {
//     await lanceToken.pay(signers[i], 20);
//     await lanceToken.connect(signers[i]).approve(evaluatorContract, 20);
//     await evaluatorContract.addEvaluator(signers[i], `ipfs${i}`);
//   }
// };

// describe("Bid Token contract", async function () {
//   it("All addresses should have desired amounts", async function () {
//     signers = await ethers.getSigners();
//     const [signer1, signer2, signer3] = await ethers.getSigners();
//     bidToken = await ethers.deployContract("BidToken", [
//       signer1.address,
//       signer2.address,
//       signer3.address,
//     ]);

//     const signer1Balance = await bidToken.balanceOf(signer1.address);
//     const signer2Balance = await bidToken.balanceOf(signer2.address);
//     const signer3Balance = await bidToken.balanceOf(signer3.address);
//     expect(signer1Balance).to.equal(30);
//     expect(signer2Balance).to.equal(10);
//     expect(signer3Balance).to.equal(20);
//   });
// });

// describe("GetBlindedBid", async function () {
//   it("BlindedBid should produce a bytes32 something", async function () {
//     const [signer1] = await ethers.getSigners();
//     getBlindedBid = await ethers.deployContract("GetBlindedBid");
//     secret = {
//       text: "lxytz",
//       byte32Text:
//         "0x6c7879747a000000000000000000000000000000000000000000000000000000",
//     };
//     const blindedBid = await getBlindedBid.getBlindedBid(30, secret.byte32Text);
//     expect(blindedBid).to.have.lengthOf(66);
//   });
// });

// describe("Vickery Auction", async function () {
//   it("Vickery Auction deploys", async function () {
//     vickeryAuction = await ethers.deployContract("BlindAuction", [
//       180,
//       180,
//       bidToken.getAddress(),
//     ]);
//   });

//   it("Bidders allowance increased successfully", async function () {
//     [signer1, signer2, signer3] = await ethers.getSigners();
//     const auctionAddress = vickeryAuction.getAddress();
//     await bidToken.connect(signer1).approve(auctionAddress, 30);
//     await bidToken.connect(signer2).approve(auctionAddress, 10);
//     await bidToken.connect(signer3).approve(auctionAddress, 20);

//     expect(
//       await bidToken.allowance(signer1.address, auctionAddress)
//     ).to.be.equal(30);
//     expect(
//       await bidToken.allowance(signer2.address, auctionAddress)
//     ).to.be.equal(10);
//     expect(
//       await bidToken.allowance(signer3.address, auctionAddress)
//     ).to.be.equal(20);
//   });

//   it("Amounts should be deducted when bid is sent", async function () {
//     const blindedBid10 = await getBlindedBid.getBlindedBid(
//       10,
//       secret.byte32Text
//     );
//     const blindedBid20 = await getBlindedBid.getBlindedBid(
//       20,
//       secret.byte32Text
//     );
//     const blindedBid30 = await getBlindedBid.getBlindedBid(
//       30,
//       secret.byte32Text
//     );

//     await vickeryAuction.bid(signer1.address, 30, blindedBid30);
//     await vickeryAuction.bid(signer2.address, 10, blindedBid10);
//     await vickeryAuction.bid(signer3.address, 20, blindedBid20);

//     expect(await bidToken.balanceOf(signer1.address)).to.be.equal(0);
//     expect(await bidToken.balanceOf(signer2.address)).to.be.equal(0);
//     expect(await bidToken.balanceOf(signer3.address)).to.be.equal(0);
//   });

//   it("The winner of the auction should pay the second highest bid", async function () {
//     await vickeryAuction.reveal([30], [secret.byte32Text], signer1.address);
//     await vickeryAuction.reveal([10], [secret.byte32Text], signer2.address);
//     await vickeryAuction.reveal([20], [secret.byte32Text], signer3.address);
//     await vickeryAuction.auctionEnd();
//     expect(await bidToken.balanceOf(signer1.address)).to.be.equal(10);
//     expect(await bidToken.balanceOf(signer2.address)).to.be.equal(10);
//     expect(await bidToken.balanceOf(signer3.address)).to.be.equal(20);
//   });

//   it("The Auction contract should hold the second highest bid", async function () {
//     const contractBalance = await bidToken.balanceOf(
//       await vickeryAuction.getAddress()
//     );
//     expect(contractBalance).to.be.equal(20);
//   });
// });

// describe("Lance Token", async function () {
//   it("Should deploy", async () => {
//     lanceToken = await ethers.deployContract("LanceToken", [
//       signer1.address,
//       signer2.address,
//       signer3.address,
//     ]);
//   });
// });

// describe("Evaluator Contract", async function () {
//   it("Should deploy", async () => {
//     evaluatorContract = await ethers.deployContract("EvaluatorContract", [
//       await lanceToken.getAddress(),
//       10,
//     ]);
//   });
//   it("should increase lance allowance successfully", async function () {
//     [signer1, signer2, signer3] = await ethers.getSigners();
//     const evaluatorAddress = evaluatorContract.getAddress();
//     await lanceToken.connect(signer1).approve(evaluatorAddress, 30);
//     await lanceToken.connect(signer2).approve(evaluatorAddress, 10);
//     await lanceToken.connect(signer3).approve(evaluatorAddress, 20);

//     expect(
//       await lanceToken.allowance(signer1.address, evaluatorAddress)
//     ).to.be.equal(30);
//     expect(
//       await lanceToken.allowance(signer2.address, evaluatorAddress)
//     ).to.be.equal(10);
//     expect(
//       await lanceToken.allowance(signer3.address, evaluatorAddress)
//     ).to.be.equal(20);
//   });

//   it("should add evaluators", async () => {
//     await evaluatorContract.addEvaluator(signer1.address, "ipfs1");
//     await evaluatorContract.addEvaluator(signer2.address, "ipfs2");
//     await evaluatorContract.addEvaluator(signer3.address, "ipfs3");
//     const evaluators = await evaluatorContract.getEvaluators();
//     expect(evaluators.length).to.be.equal(3);
//   });

//   it("should increment stake", async () => {
//     await evaluatorContract.increaseStake(signer3.address, 10);
//     const evaluators_ = await evaluatorContract.getEvaluators();
//     expect(evaluators_[2][1]).to.be.equal(20);
//   });

//   it("should decrement stake", async () => {
//     await evaluatorContract.decreaseStake(signer3.address, 10);
//     const evaluators_ = await evaluatorContract.getEvaluators();
//     expect(evaluators_[2][1]).to.be.equal(10);
//   });

//   // it("should remove evaluators", async () => {
//   //   expect(await lanceToken.balanceOf(signer1.address)).to.be.equal(20);
//   //   await evaluatorContract.removeEvaluator(signer1.address);
//   //   const evaluatorRemoved = await evaluatorContract.checkEvaluatorRemoved(
//   //     signer1.address
//   //   );
//   //   // console.log(evaluatorRemoved);
//   //   expect(evaluatorRemoved).to.be.equal(true);
//   //   expect(await lanceToken.balanceOf(signer1.address)).to.be.equal(30);
//   // });

//   it("subbract tests", async () => {
//     // console.log("Difference: ", await getBlindedBid.subract(1, 2));
//   });
// });

// describe("Evaluation Contract", async function () {
//   it("should populate evaluators", async () => {
//     await addEvaluators(15, evaluatorContract);
//     const totalEvaluators = await evaluatorContract.getEvaluators();
//     expect(totalEvaluators.length).to.be.equal(15);

//     evaluationContract = await ethers.deployContract("Evaluation", [
//       await evaluatorContract.getAddress(),
//       await lanceToken.getAddress(),
//       await bidToken.getAddress(),
//       fees * decimals,
//       10,
//       decimals,
//       heuristicAllocation * decimals,
//       evaluatorAllocation * decimals,
//       MedianShares * decimals,
//       NonMedianShares * decimals,
//     ]);

//     lanceToken.pay(await evaluationContract.getAddress(), fees * decimals);
//     bidToken.pay(await evaluationContract.getAddress(), fees * decimals);

//     const selectedEvaluators = await evaluationContract.getEvaluators();
//     expect(selectedEvaluators.length).to.be.equal(10);
//   });

//   it("should submit client score", async () => {
//     await evaluationContract.submitOwnerScore(
//       signer1.address,
//       ownerScore * decimals
//     );
//     expect(await evaluationContract.ownerScore()).to.be.equal(
//       ownerScore * decimals
//     );
//   });

//   it("should submit evaluator scores", async () => {
//     const selectedEvaluators = await evaluationContract.getEvaluators();
//     for (let i = 0; i < selectedEvaluators.length; i++) {
//       await evaluationContract.submitEvaluatorScore(
//         selectedEvaluators[i],
//         algoScores[i] * decimals,
//         heuristicScores[i] * decimals
//       );
//     }

//     const [algoScores_, heuristicScores_] =
//       await evaluationContract.getEvaluatorScores();
//     expect(algoScores_.length).to.be.equal(heuristicScores_.length);

//     for (let i = 0; i < algoScores_.length; i++) {
//       expect(algoScores_[i]).to.be.equal(algoScores[i] * decimals);
//       expect(heuristicScores_[i]).to.be.equal(heuristicScores[i] * decimals);
//     }
//   });

//   it("should correctly evaluate algo and heuristic scores", async () => {
//     await evaluationContract.evaluate();
//     expect(await evaluationContract.averageHeuristic()).to.be.equal(
//       heuristicMean * decimals
//     );
//     expect(await evaluationContract.averageAlgo()).to.be.equal(
//       algoMean * decimals
//     );
//     expect(await evaluationContract.lowerIQRAlgo()).to.be.equal(
//       algoIQRLower * decimals
//     );
//     expect(await evaluationContract.upperIQRAlgo()).to.be.equal(
//       algoIQRUpper * decimals
//     );
//     expect(await evaluationContract.upperIQRHeuristic()).to.be.equal(
//       heuristicIQRUpper * decimals
//     );
//     expect(await evaluationContract.lowerIQRHeuristic()).to.be.equal(
//       heuristicIQRLower * decimals
//     );
//   });

//   it("should correctly evaluate overall score", async () => {
//     expect(await evaluationContract.overallScore()).to.be.equal(
//       Math.round(overallScore * decimals)
//     );
//   });

//   it("should correctly distribute funds to evaluators", async () => {
//     const selectedEvaluators = await evaluationContract.getEvaluators();
//     //Skip the first 3 signers because they already have some tokens, the rest were given an extra 10
//     for (let i = 4; i < selectedEvaluators.length; i++) {
//       expect(await lanceToken.balanceOf(selectedEvaluators[i])).to.be.equals(
//         balances[i] + 10
//       );
//     }
//   });
// });
