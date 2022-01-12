module Visualization

import IO;
import ValueIO;
import util::Math;

import vis::Figure;
import vis::Render;
import vis::KeySym;

import Map;
import ListRelation;
import List;
import Set;
import String;

import TestCoverage;

// aliases
alias UnitCC = lrel[str uName, int uSize, int cc];

// global vars
Figure dataView = box(fillColor(rgb(0, 0, 0, 0.0)));
bool selected = false;
map[str, str] ratingColorMapper = ("--":"red", "-":"Salmon", "o":"white", "+":"Chartreuse", "++":"Lime");

// point generator
Figure point(num x, num y) = ellipse(shrink(0.05), fillColor("red"), align(x, y));

public void run(){
	
	//loc ccPath = |project://sotfqm_op1/data/JabberPoint_unitcc.txt|;
	//loc tCoverPath = |project://sotfqm_op1/data/JabberPoint_testcoverage.txt|;
	
	loc ccPath = |project://sotfqm_op1/data/hsqldb_unitcc.txt|;
	loc tCoverPath = |project://sotfqm_op1/data/hsqldb_testcoverage.txt|;
	
	//loc ccPath = |project://sotfqm_op1/data/smallsql_unitcc.txt|;
	//loc tCoverPath = |project://sotfqm_op1/data/smallsql_testcoverage.txt|;
	
	renderTreemap(ccPath, tCoverPath);
}

public void renderScatterplot(loc path){
	
	map[str, UnitCC] ccMetric = readTextValueFile(#map[str, UnitCC], path);

	UnitCC mapContent = joinMapContent(ccMetric);
	int maxCC = max(mapContent.cc);
	int maxUnit = max(mapContent.uSize);

	Figure scatterplot = overlay([ 
		point(
			valueMapper(usize, 0, maxUnit, 0.0, 1.0), 
			valueMapper(cc, 0, maxCC, 1.0, 0.0)
		) | <_, int usize, int cc> <- mapContent ], width(800), height(800));
	
	render(scatterplot);
}

public void renderTreemap(loc ccPath, loc tCoverPath){

	map[str, int] tCoverMetric = readTextValueFile(#map[str, int], tCoverPath);
	map[str, UnitCC] ccMetric = readTextValueFile(#map[str, UnitCC], ccPath);
	
	UnitCC mapContent = joinMapContent(ccMetric);
	int maxCC = max(mapContent.cc);
	int maxUnit = max(mapContent.uSize);
	
	list[Figure] tmap = [ 
		box(
			treemap([box(area(s), fillColor(lerpColor(max(cont.cc), maxCC, "PaleTurquoise", "Teal"))) | <_, int s, int cc> <- cont], shrink(0.9)), // max cc per class gebruikt om overzichtelijk te houden maar kan ook cc per method weergeven
			area(valueMapper(sum([0]+cont.uSize), 1, maxUnit, 10, 30)),
			onClickElement(fpath, cont, maxCC, tCoverMetric),
			//fillColor(meanTestCoverage(fpath, tCoverMetric, size(cont))),
			lineColor(rgb(0, 0, 0, 0.0))
			)
	 	| <str fpath, UnitCC cont> <- toList(ccMetric)];
	
	render(computeFigure(Figure () {return overlay([treemap(tmap), dataView]);}));
}

public str meanTestCoverage(str fpath, map[str, int] tCovermetric, int numUnits){
	str className = parseClassName(fpath);
	real sumCovered = toReal((0 | it + covered | <str name, int covered> <- toRel(tCovermetric), substring(name, 1, findLast(name, "/")) == className));
	
	return ratingColorMapper[rating(sumCovered/numUnits*100.0)];
}

public FProperty onClickElement(str fpath, UnitCC content, int maxCC, map[str, int] tCoverMetric){
	return onMouseDown(bool (int _, map[KeyModifier,bool] _) {
		
		
		if (!selected) {

			list[Figure] tmap = [box(
				box(fillColor(lerpColor(cc, maxCC, "PaleTurquoise", "Teal")), shrink(0.9)),
				area(s),
				//testCoverageLineColor(tCoverMetric, name, parseClassName(fpath)),
				//fillColor(lerpColor(cc, maxCC, "PaleTurquoise", "Teal")),
				onHover(name, s, cc)
				)| <str name, int s, int cc> <- content];
			
			dataView = box(
				vcat([
						text("Class path: <fpath>\t\t\tTotal unit size: <sum(content.uSize)> LOC\t\t\tTotal Complexity: <sum(content.cc)>", fontBold(true)), 
						treemap(tmap)
					], 
					gap(10), 
					shrink(0.98)),
				fillColor("MistyRose"), 
				shrink(0.95), 
				shadow(true));
			
			selected = true;
		} else {
			selected = false;
			dataView = box(fillColor(rgb(0, 0, 0, 0.0)));
		}
		
		return true;
	});
}

public FProperty onHover(str unitName, int usize, int cc){
	return mouseOver(box(text("Unit name: <unitName>\nUnit size: <usize> LOC\nComplexity: <cc>"), resizable(false), grow(1.2)));
}

//public FProperty testCoverageLineColor(map[str, int] tCoverMetric, str methodName, str className){
//	if (/(T|t)est/ := className){
//		return fillColor("Yellow");
//	} else if ("/<className>/<methodName>" notin tCoverMetric){
//		//println("/<className>/<methodName>");
//		// TODO: classname en method name zijn niet voldoende om door de covermetric te kijken
//		//println(tCoverMetric);
//		return fillColor("Gray");
//	}
//	return fillColor(tCoverMetric["/<className>/<methodName>"] == 1 ? "Lime" : "White");
//}


// parse the class name out of the string path
public str parseClassName(str fpath){
	int begin = findLast(fpath, "/") + 1;
	int end = findFirst(fpath, ".");
	if (begin >= end) throw "Error at parsing class path in meanTestCoverage";
	
	return substring(fpath, begin, end);
}

// join lists of tuples in map into one list of tuples
public UnitCC joinMapContent(map[str, UnitCC] input){
	return reducer(range(input), UnitCC (UnitCC a, UnitCC b) {return a + b;}, []);
}

// maps a numeric value n from one number space (start1 - stop1) to another number space (start2 - stop2) 
// by normalizing the value first and then applying the given number space
private real valueMapper(num n, num start1, num stop1, num start2, num stop2) {
	return ((toReal(n)-toReal(start1))/(toReal(stop1)-toReal(start1)))*(toReal(stop2)-toReal(start2))+toReal(start2);
}

// linearly interpolate between two colors given a number n and the max value for n
private Color lerpColor(num n, num maxN, str c1, str c2){
	return interpolateColor(color(c1), color(c2), valueMapper(n, 0.0, maxN, 0.0, 1.0));
}




