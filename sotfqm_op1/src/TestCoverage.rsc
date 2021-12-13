module TestCoverage

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Map;
import List;
import String;


public void run(){
	//M3 model = createM3FromEclipseProject(|project://hsqldb|);
	//M3 model = createM3FromEclipseProject(|project://smallsql|);
	M3 model = createM3FromEclipseProject(|project://JabberPoint|);
	
	testCoverage(model);
}

public str testCoverage(model){

	// map of all methods that are:
	// 1. not associated by name with "test" 
	// 2. and are defined as java methods (no constructors) 
	map[str, int] allMethods = (trimArgs(m.path): 0 | m <- methods(model), 
		!(/(t|T)est/ := m.path), 
		m.scheme == "java+method");
	
	// set of all file locations associated by name with "test"
	set[loc] testFiles = {f | f <- files(model), /(t|T)est/ := f.path};
	
	// for every test java file
	for (f <- testFiles){
	
		Declaration decl = createAstFromFile(f, false);
		
		// test class fields
		map[value, value] fields = ();
		
		// test class method parameters/arguments
		map[value, value] args = ();
		// test class method local variables
		map[value, value] localVars = ();
		
		// top down visit to set the fields, args, and localvars first before assessing the method calls
		top-down visit(decl){
			case \method(_,_, list[Declaration] parameters,_,Statement impl):{
				// set method arguments by name: type
				args = ();
				args = (name: parseDataType(\type) | arg <- parameters, \parameter(Type \type, str name,_) := arg);
				
				// set local variables of method by name: type
				localVars = ();
				localVars = (var[0]: parseDataType(\type) | /\variables(Type \type, list[Expression] \fragments) <- impl, var <- fragments);
			}
			// set class fields 
			case \field(Type \type, list[Expression] fragments): fields += (var[0]: parseDataType(\type) | var <- fragments);
			case \methodCall(false,Expression receiver, str name,_): {
				
				// receiver of the method call 
				rec = parseDataType(receiver);
				
				// value rec is either the name of a local variable, the name of a method arg, the name of a class field or the name of a class
				// by determining if rec is in either localvars/args/fields, we can acquire the class name and set allMethods
				// if rec is either a direct instantiation of an object or the method is a static method, we can use rec directly to query the map
				if (rec in localVars){
					allMethods["/<localVars[rec]>/<name>"] = 1;
				} else if (rec in args) {
					allMethods["/<args[rec]>/<name>"] = 1;
				} else if (rec in fields) {
					allMethods["/<fields[rec]>/<name>"] = 1;
				} else {
					allMethods["/<rec>/<name>"] = 1;
				}
			}
		}
	}
	
	// reducer that counts all values in the allMethods map 
	real numMethodsCalled = ( 0.0 | it + v | <_,v> <- toRel(allMethods));
	// percentage test code coverage 
	real coverage = numMethodsCalled / size(allMethods) * 100.0;
	println("Test Code Coverage: <coverage>%");
	return rating(coverage);
}

public str rating(real coverage){
	if (coverage < 20) {
		return "--";
	} else if (coverage >= 20 && coverage < 60) {
		return "-";
	} else if (coverage >= 60 && coverage < 80) {
		return "o";
	} else if (coverage >= 80 && coverage < 95) {
		return "+";
	} else {
		return "++";
	}
}

// find first string in an Algebraic Data Type
// in use: find the class name, if nothing is found, return placeholder primitive type (meant for error checking)
public str parseDataType(t){
	visit(t){
		case str name: return name;
	}
	return "primitive type";
}

// trim the part starting with the open parenthesis "("
public str trimArgs(str method){
	int openingBrace = findFirst(method, "(");
	return substring(method, 0, openingBrace);
}

