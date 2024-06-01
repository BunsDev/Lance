function getIQR(arr) {
  let upperHalf = getUpperHalf(arr.sort());
  let lowerHalf = getLowerHalf(arr.sort());
  let q3 = getMedian(upperHalf);
  let q1 = getMedian(lowerHalf);
  let IQR = q3 - q1;
  let upperIQR = q3 + (IQR * 3) / 2;
  let lowerIQR;
  if (q1 < (IQR * 3) / 2) {
    lowerIQR = 0;
  } else {
    lowerIQR = q1 - (IQR * 3) / 2;
  }
  return [upperIQR, lowerIQR];
}

function getPunishmentStake(totalPunishable, average, actual, previousStake) {
  return (
    previousStake -
    (totalPunishable * (Math.abs(average - actual) / actual)) / 2
  );
}

function getMean(arr) {
  let total = 0;
  for (let i = 0; i < arr.length; i++) {
    total = total + arr[i];
  }
  return Math.floor(total / arr.length);
}

function getMedian(array_) {
  const array = array_.sort();
  if (array.length == 0) {
    return 0;
  }
  if (array.length % 2 == 0) {
    let medianIndice1 = Math.floor(array.length / 2);
    let medianIndice2 = medianIndice1 - 1;
    let median1 = array[medianIndice1];
    let median2 = array[medianIndice2];
    return Math.floor((median1 + median2) / 2);
  } else {
    let medianIndex = Math.floor(array.length / 2);
    return array[medianIndex];
  }
}

function getUpperHalf(arr) {
  let arrLength = Math.floor(arr.length / 2);
  let upperHalf = [];
  if (arr.length % 2 == 0) {
    for (let i = arrLength; i < arr.length; i++) {
      upperHalf[i - arrLength] = arr[i];
    }
    return upperHalf;
  } else {
    for (let i = arrLength + 1; i < arr.length; i++) {
      upperHalf[i - arrLength - 1] = arr[i];
    }
    return upperHalf;
  }
}

function getLowerHalf(arr) {
  let arrLength = Math.floor(arr.length / 2);
  let lowerHalf = [];
  for (let i = 0; i < arrLength; i++) {
    lowerHalf[i] = arr[i];
  }
  return lowerHalf;
}

function getRewards(arrShares, tokens) {
  let totalShares = 0;
  for (let share of arrShares) {
    totalShares = share + totalShares;
  }
  const distributionArray = [];
  for (let i = 0; i < arrShares.length; i++) {
    distributionArray[i] = Math.floor((arrShares[i] / totalShares) * tokens);
  }
  return distributionArray;
}

function getOverallScore(algoMean, heursiticMean, ownerScore) {
  return Math.floor(
    (algoMean * 0.6 + heursiticMean * 0.4) * 0.7 + ownerScore * 0.3
  );
}

function getShares(array, median, medianScore, notMedianScore, lower, upper) {
  return array.map((el) => {
    if (el == median) {
      return medianScore;
    } else if (el > lower && el <= upper) {
      return notMedianScore;
    } else {
      return 0;
    }
  });
}

function sumArray(arr, arr1) {
  if (arr == arr1) return "Arrays arent equal";
  let newArr = [];
  for (let i = 0; i < arr.length; i++) {
    newArr[i] = arr[i] + arr1[i];
  }
  return newArr;
}
