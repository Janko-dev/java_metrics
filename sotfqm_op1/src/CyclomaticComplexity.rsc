module CyclomaticComplexity


import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Functions;

import List;
import String;
import Map;

public str cyclomaticComplexity(M3 model){
	
	// relation between unit(method)size and Cyclomatic Complexity of set unit (unitsize -> CC)
	lrel[int, int] complexityUnitMetric = calCCAndUnitSize(model);
	
	// aggregate measured data in categories 
	map[str, real] risk = riskMapping(complexityUnitMetric);
	
	println("--- Cyclomatic Complexity ---");
	resultsPrinter(risk);
	
	return ratingCyclomaticComplexity(risk);;
}

// map metrics in the following categories: low, moderate, high and very high; based on the SIG categorization of Cyclomatic Complexity
private map[str, real] riskMapping(lrel[int, int] CCmetrics){
	map[str, real] risk = ("low" : 0.0, "moderate" : 0.0, "high" : 0.0, "veryHigh" : 0.0);
	int totalLOC = 0;
	for (<unitSize, cycloComplexity> <- CCmetrics){
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


// return list relation between unit size (per method) and cyclomatic complexity of set method
private lrel[int, int] calCCAndUnitSize(M3 model){
	
	lrel[int, int] complexityMethods = [];
	
	for (f <- files(model)){
		
		// abstract syntax tree (AST) for each file in the project
		Declaration decl = createAstFromFile(f, false);
		
		visit(decl){
			// visit every method; calculate the unitsize metric, 
			// calculate the cyclomatic complexity per unit + possible method exceptions (since they also control the flow of the program)
			case md: \method(_,_,_,list[Expression] exceptions,Statement impl): complexityMethods += <size(trimLoc(md.src)), CCPerUnit(impl) + size(exceptions)>;
		}
	}
	return complexityMethods;
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
		//case \break(): n+=1;
		//case \break(_): n+=1;
		//case \continue(): n+=1;
		//case \continue(_): n+=1;
		case \try(_,list[Statement] catchClauses): n+=size(catchClauses);
		case \try(_,list[Statement] catchClauses,_): n+=size(catchClauses) + 1;
		case ret: \return(_): n+=isLastReturn(ret, methodBody);
		case ret: \return(): n+=isLastReturn(ret, methodBody);
		case "&&": n+=1;
		case "||": n+=1;
	}
	return n;
}

// determine if a statement is the last statement in a unit(method)
// in use: the last return statement in a method should not be counted as a linearly independent path
private int isLastReturn(Statement ret, Statement methodBody){
	switch(methodBody) {
		case \block(list[Statement] statements): return ret.src == statements[size(statements)-1].src ? 0 : 1;
	}
	return 0;
}