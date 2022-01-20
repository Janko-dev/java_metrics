module UnitSize

import IO;
import String;
import List;
import Set;
import lang::java::m3::Core;

import Functions;

// calculate and print unit size
public str unitSize(M3 m3) {
//Method list
  list[loc] locMethods = toList(methods(m3));
  println("number of units: <size(locMethods)>");
//map lvl label and lvl % size  
  map[str, real] riskLevels = calRiskLevels(locMethods);
// Output  
  println("--------- Unit Size ---------");
  resultsPrinter(riskLevels);
// generate risk score
  return ratingUnitSize(riskLevels);
}

// Calculates percentage of total for each risk level
private map[str, real] calRiskLevels(list[loc] locMethods) {
// initialize the map risk to 0.0's for all categories
  map[str, real] risks = ("low" : 0.0, "moderate" : 0.0, "high" : 0.0, "veryHigh" : 0.0);
  int totalLoc = 0;

  // get unit size for each method, linecount and total count
  // SIG thresholds  https://www.softwareimprovementgroup.com/wp-content/uploads/
  // 2021-SIG-TUViT-Evaluation-Criteria-Trusted-Product-Maintainability-Guidance-for-producers.pdf
  for(loc method <- locMethods) {
    int countLines = size(trimLoc(method));
    if(countLines <= 15) {
      risks["low"] += countLines;
    } else if (countLines <= 30) {
      risks["moderate"] += countLines;
    } else if (countLines <= 60) {
      risks["high"] += countLines;
    } else {
      risks["veryHigh"] += countLines;
    }
    totalLoc += countLines;
  }
// riskPercentages will calculate the % given the totallines and lines per category
  return riskPercentages(risks, totalLoc);
}
