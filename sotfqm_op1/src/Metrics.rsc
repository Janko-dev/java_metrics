module Metrics

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;

import DateTime;

import Volume;
import UnitSize;
import Clones;
import Functions;
import CyclomaticComplexity;
import TestCoverage;

public void runMetricsHSQL() {
	loc hsql = |project://hsqldb/|;
	println("HSql");
	runMetrics(hsql);
}

public void runMetricsSmallSql() {
	loc smallsql = |project://smallsql/|;
	println("SmallSql");
	runMetrics(smallsql);
}

public void runMetrics(loc path) {
	datetime startTime = now();
  
	M3 m3 = createM3FromEclipseProject(path);
	println("----");
	map[str, str] scores = ();
	  
	// Calculate volume once to reuse in following code 
	tuple[int lines, str score] vol = volume(path);
	  
	scores["Volume score"] = vol.score;
	scores["Unit size score"] = unitSize(m3);
	scores["Unit complexity score"] = cyclomaticComplexity(m3, path);
	scores["Unit Test Coverage score"] = testCoverage(m3, path);
	scores["Duplication score"] = findClones(path, false, vol.lines);
	  
	scorePrinter(scores);
	
	// aggregate metrics based on SIG's ISO 9126 maintainability matrix
	str analysability = aggregateScores([scores["Volume score"], scores["Duplication score"], scores["Unit size score"], scores["Unit Test Coverage score"]]);
	str changeability = aggregateScores([scores["Unit complexity score"], scores["Duplication score"]]);
	str stability     = aggregateScores([scores["Unit Test Coverage score"]]);
	str testability   = aggregateScores([scores["Unit complexity score"], scores["Unit size score"], scores["Unit Test Coverage score"]]);
	  
	println("Analysability score: <analysability>");
	println("Changeability score: <changeability>");
	println("Stability score:     <stability>");
	println("Testability score:   <testability>");
	  
	println("\nMaintainability score: <aggregateScores([analysability, changeability, stability, testability])>");
	
	// calculate run time
	datetime endTime = now();
	dur = endTime - startTime;
	println("Runtime: <dur.hours> hours <dur.minutes> minutes <dur.seconds> seconds");   
}
