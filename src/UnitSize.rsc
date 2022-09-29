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

//Unit size rating, SIG Thresholds (only 4stars found, Rest still missing)
//To be eligible for certification at the level of 4 stars, for each programming language used:
//The percentage of lines of code residing in units with more than 15 lines of code should not exceed 42.3%.
//percentage in units with more than 30 lines of code should not exceed 18.5%.
//The percentage in units with more than 60 lines should not exceed 5.4%.
public str ratingUnitSize(map[str, real] riskLevels) {
  	if(riskLevels["moderate"] <= 25 && riskLevels["high"] == 0 && riskLevels["veryHigh"] == 0) {
    	return "++";
  	} else if(riskLevels["moderate"] <= 30 && riskLevels["high"] <= 5 && riskLevels["veryHigh"] == 0) {
    	return "+";
  	} else if(riskLevels["moderate"] <= 40 && riskLevels["high"] <= 10 && riskLevels["veryHigh"] == 0) {
    	return "o";
  	} else if(riskLevels["moderate"] <= 42.3 && riskLevels["high"] <= 18.5 && riskLevels["veryHigh"] <= 5.4) {
    	return "-";
  	} else {
    	return "--";
  	}
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
