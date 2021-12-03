module Metrics

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;

import Functions;
import Volume;
import UnitSize;
import CyclomaticComplexity;

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
  
  scorePrinter(scores);
}
