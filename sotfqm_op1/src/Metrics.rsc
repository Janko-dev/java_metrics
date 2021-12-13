module Metrics

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;

import Volume;
import UnitSize;
import Clones;
import Functions;
import CyclomaticComplexity;
import TestCoverage;

import Map;
import Set;

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
  M3 m3 = createM3FromEclipseProject(path);
  println("----");
  map[str, str] scores = ();
  
  scores["Volume score"] = volume(path);
  scores["Unit size score"] = unitSize(m3);
  scores["Unit complexity score"] = cyclomaticComplexity(m3);
  scores["Unit Test Coverage"] = testCoverage(m3);
  scores["Duplication"] = findClones(path);
  
  scorePrinter(scores);
  
  list[str] analysability = [scores["Volume score"], scores["Duplication"], scores["Unit size score"], scores["Unit Test Coverage"], "o"];
  list[str] changeability = [scores["Unit complexity score"], scores["Duplication"], "-"];
  list[str] stability     = [scores["Unit Test Coverage"], "o"];
  list[str] testability   = [scores["Unit complexity score"], scores["Unit size score"], scores["Unit Test Coverage"], "-"];
  
  println("Analysability score: <aggregateScores(analysability)>");
  println("Changeability score: <aggregateScores(changeability)>");
  println("Stability score: <aggregateScores(stability)>");
  println("Testability score: <aggregateScores(testability)>");
  
  println("\nMaintainability score: <aggregateScores(toList(range(scores)))>");
}
