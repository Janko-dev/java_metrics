module TestCoverage

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Map;
import List;
import Set;
import String;

public void run(){

	M3 model = createM3FromEclipseProject(|project://smallsql|);
	//M3 model = createM3FromEclipseProject(|project://JabberPoint|);
	
	map[str, int] allMethods = (trimLoc(m): 0 | m <- methods(model), !(/(t|T)est/ := m.path), m.scheme != "java+initializer");
	set[loc] testFiles = {f | f <- files(model), /(t|T)est/ := f.path};
	
	for (f <- testFiles){
	
		Declaration decl = createAstFromFile(f, false);
		
		map[value, value] fields = ();
		
		map[value, value] args = ();
		map[value, value] localVars = ();
		
		top-down visit(decl){
			case \method(_,_, list[Declaration] parameters,_,Statement impl):{
				args = ();
				args = (name: findFirstStr(\type) | arg <- parameters, \parameter(Type \type, str name,_) := arg);
				
				localVars = ();
				localVars = (frag[0]: findFirstStr(\type) | /\variables(Type \type, list[Expression] \fragments) <- impl, frag <- fragments);
			}
			case \field(Type \type, list[Expression] fragments): fields += (var[0]: findFirstStr(\type) | var <- fragments);
			case \methodCall(false,Expression receiver, str name,_): {
				
				rec = findFirstStr(receiver);
				
				if (rec in localVars){
					//println("<localVars[rec]> -- <name>");
					allMethods["/<localVars[rec]>/<name>"] = 1;
				} else if (rec in args) {
					//println("<args[rec]> -- <name>");
					allMethods["/<args[rec]>/<name>"] = 1;
				} else if (rec in fields) {
					//println("<fields[rec]> -- <name>");
					allMethods["/<fields[rec]>/<name>"] = 1;
				} else {
					//println("<rec> -- <name>");
					allMethods["/<rec>/<name>"] = 1;
				}
			}
			// receiver is een string, dus checken in args/localvars/fields welk type het is
			// er is geen receiver dus checken welk type het is
			// wanneer type gevonden is, dan in allmethods zoeken naar loc met type en method naam, en die dan op true zetten;
			// berekenen welke proportie true is van het totaal, percentage van maken
		}
		//println(fields);
		//println(args);
		//println(localVars);
	}
	println(( 0.0 | it + v | <_,v> <- toRel(allMethods)) / size(allMethods) * 100.0);
}

public value findFirstStr(t){
	visit(t){
		case str name: return name;
	}
	return t;
}

public str trimLoc(loc l){
	int openingBrace = findFirst(l.path, "(");
	return substring(l.path, 0, openingBrace);
}

