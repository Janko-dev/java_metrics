module Metrics

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;
import Volume;
import UnitSize;

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
  volume(path);
  unitSize(m3);
}
