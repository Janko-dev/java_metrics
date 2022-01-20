module CyclomaticComplexity

import IO;
import ValueIO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Functions;

import List;
import String;
import Map;
import Set;

alias UnitCC = lrel[str, int, int];

public str cyclomaticComplexity(M3 model, loc path){
	
	// relation between unit(method)size and Cyclomatic Complexity of set unit (unitsize -> CC)
	map[str, UnitCC] complexityUnitMetric = calCCAndUnitSize(model);
	
	// Write to .txt file
	writeTextValueFile(|project://sotfqm_op1/data/| + "<path.authority>_unitcc.txt", complexityUnitMetric);
	
	// aggregate measured data in categories 
	map[str, real] risk = riskMapping(complexityUnitMetric);
	
	println("--- Cyclomatic Complexity ---");
	resultsPrinter(risk);
	
	return ratingCyclomaticComplexity(risk);;
}

// map metrics in the following categories: low, moderate, high and very high; based on the SIG categorization of Cyclomatic Complexity
private map[str, real] riskMapping(map[str, UnitCC] CCmetrics){
	map[str, real] risk = ("low" : 0.0, "moderate" : 0.0, "high" : 0.0, "veryHigh" : 0.0);
	int totalLOC = 0;
	
	UnitCC joinedList = reducer(range(CCmetrics), UnitCC (UnitCC a, UnitCC b) {return a + b;}, []);
	
	for (<_, unitSize, cycloComplexity> <- joinedList){
		if (cycloComplexity <= 10){
			risk["low"] += unitSize;
		} else if (cycloComplexity >= 11 && cycloComplexity <= 20){
			risk["moderate"] += unitSize;
		} else if (cycloComplexity >= 21 && cycloComplexity <= 50){
			risk["high"] += unitSize;
		} else if (cycloComplexity > 50){
			risk["veryHigh"] += unitSize;
		}
		totalLOC+=unitSize;
	}
	
	return (k:v/totalLOC*100.0 | <k,v> <- toRel(risk));
}

// Rating based on the scoring scheme used by the Software Improvement Group (SIG)
public str ratingCyclomaticComplexity(map[str, real] riskLevels) {
  if(riskLevels["moderate"] <= 25 && riskLevels["high"] == 0 && riskLevels["veryHigh"] == 0) {
    return "++";
  } else if(riskLevels["moderate"] <= 30 && riskLevels["high"] <= 5 && riskLevels["veryHigh"] == 0) {
    return "+";
  } else if(riskLevels["moderate"] <= 40 && riskLevels["high"] <= 10 && riskLevels["veryHigh"] == 0) {
    return "o";
  } else if(riskLevels["moderate"] <= 50.3 && riskLevels["high"] <= 15 && riskLevels["veryHigh"] <= 5) {
    return "-";
  } else {
    return "--";
  }
}

// return list relation between unit size (per method) and cyclomatic complexity of set method
private map[str, UnitCC] calCCAndUnitSize(M3 model){
	
	map[str, UnitCC] complexityMethods = ();
	//lrel[loc file, str methodname, int unitsize, int cc] complexityMethods = [];
	
	set[loc] javaFiles = { f | f <- files(model), f.extension == "java" };
	
	for (f <- javaFiles){
		
		// abstract syntax tree (AST) for each file in the project
		Declaration decl = createAstFromFile(f, false);
		
		complexityMethods[f.path] = [];
		
		visit(decl){
			// visit every method; calculate the unitsize metric, 
			// calculate the cyclomatic complexity per unit + possible method exceptions (since they also control the flow of the program)
			case md: \method(_,str name,_,list[Expression] exceptions,Statement impl): 
				complexityMethods[f.path] += <name, size(trimLoc(md.src)), CCPerUnit(impl) + size(exceptions)>;
		}
	}
	
	return (k:v | <str k, UnitCC v> <- toList(complexityMethods), size(v) > 0);
}

// recursively visit the abstract syntax tree of a method body and count the number of linearly independent paths 
public int CCPerUnit(Statement methodBody){
	int n = 1;
	visit(methodBody){
		case \foreach(_,_,_): n+=1;
		case \for(_,_,_,_): n+=1;
		case \for(_,_,_): n+=1;
		case \if(_,_,_): n+=1;
		case \if(_,_): n+=1;
		case \case(_): n+=1;
		case \defaultCase(): n+=1;
		case \while(_,_): n+=1;
		case \do(_,_): n+=1;
		case \try(_,list[Statement] catchClauses): n+=size(catchClauses);
		case \try(_,list[Statement] catchClauses,_): n+=size(catchClauses) + 1;
		case \conditional(_,_,_): n+=1;
		case ret: \return(_): n+=isLastReturn(ret, methodBody);
		case ret: \return(): n+=isLastReturn(ret, methodBody);
		case "&&": n+=1;
		case "||": n+=1;
	}
	return n;
}

// determine if a statement is the last statement in a unit (method)
// in use: the last return statement in a method should not be counted as a linearly independent path
// all return statements before cause linearly independent paths
private int isLastReturn(Statement ret, Statement methodBody){
	switch(methodBody) {
		case \block(list[Statement] statements): return ret.src == statements[size(statements)-1].src ? 0 : 1;
	}
	return 0;
}