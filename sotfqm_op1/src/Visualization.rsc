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

public void run(){
	
	//loc ccPath = |project://sotfqm_op1/data/JabberPoint_unitcc.txt|;
	//loc tCoverPath = |project://sotfqm_op1/data/JabberPoint_testcoverage.txt|;
	
	//loc ccPath = |project://sotfqm_op1/data/hsqldb_unitcc.txt|;
	//loc tCoverPath = |project://sotfqm_op1/data/hsqldb_testcoverage.txt|;
	//loc dupsPath = |project://sotfqm_op1/data/hsqldb_dups.txt|;
	
	loc ccPath = |project://sotfqm_op1/data/smallsql_unitcc.txt|;
	loc tCoverPath = |project://sotfqm_op1/data/smallsql_testcoverage.txt|;
	loc dupsPath = |project://sotfqm_op1/data/smallsql_dups.txt|;
	
	renderTreemap(ccPath, tCoverPath, dupsPath);
}

// Read the files containing the metric data of unit size, cyclomatic complexity, unit test coverage and duplication per file.
// visualize de data in the form of a treemap (classes) of treemaps (methods)
public void renderTreemap(loc ccPath, loc tCoverPath, loc dupsPath){
	
	// read metric data
	map[str, int] tCoverMetric = readTextValueFile(#map[str, int], tCoverPath);
	map[str, int] dupsMetric = (f.path:n | <loc f, int n> <- toRel(readTextValueFile(#map[loc, int], dupsPath)));
	map[str, UnitCC] ccMetric = readTextValueFile(#map[str, UnitCC], ccPath);
	
	UnitCC joinedContent = reducer(range(ccMetric), UnitCC (UnitCC a, UnitCC b) {return a + b;}, []);
	
	// calculate maxima for visualisation 
	int maxDups = max(range(dupsMetric));
	int maxCC = max(joinedContent.cc);
	int maxUnit = max(joinedContent.uSize);
	
	int totalDups = (0 | it + n | <_, int n> <- toRel(dupsMetric));
	
	// construct the list of files, each containing a treemap of methods
	list[Figure] tmap = [
		box(
			treemap([box(area(s), fillColor(lerpColor(max(cont.cc), maxCC, "PaleTurquoise", "Teal"))) | <_, int s, _> <- cont], shrink(0.9)),
			area(valueMapper(sum([0]+cont.uSize), 1, maxUnit, 10, 30)),
			onClickElement(fpath, cont, maxCC, tCoverMetric, dupsMetric[fpath], totalDups),
			fillColor(lerpColor(dupsMetric[fpath], maxDups, "white", "DarkRed")))
	 	| <str fpath, UnitCC cont> <- toList(ccMetric)];
	
	render(computeFigure(Figure () {return overlay([treemap(tmap), dataView]);}));
}

// on click handler that opens a popup and shows the treemap of methods inside a java file
public FProperty onClickElement(str fpath, UnitCC content, int maxCC, map[str, int] tCoverMetric, int dups, int totalDups){
	return onMouseDown(bool (int _, map[KeyModifier,bool] _) {
		
		if (!selected) {
			
			str trimmedPath = substring(fpath, findLast(fpath, "/") + 1, findFirst(fpath, "."));
			
			list[Figure] tmap = [box(
				ellipse(shrink(0.5), aspectRatio(1.0), testCoverageFillColor(trimmedPath, name, tCoverMetric)),
				fillColor(lerpColor(cc, maxCC, "PaleTurquoise", "Teal")),
				area(s),
				onHover(name, <s, precision(toReal(s)/sum(content.uSize)*100, 3)>, <cc, precision(toReal(cc)/sum(content.cc)*100, 3)>)
				)| <str name, int s, int cc> <- content];
			
			// set dataView to the popup with treemap of selected class
			dataView = box(
				vcat([
						getFileData(fpath, sum(content.uSize), sum(content.cc), <dups, totalDups>), 
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
			// make dataView invisible when clicking on the screen again
			dataView = box(fillColor(rgb(0, 0, 0, 0.0)));
		}
		
		return true;
	});
}

// construct and return text figure of a java file including metrics
public Figure getFileData(str fpath, int classVolume, int totalCC, tuple[int amt, int total] dups){
	return text("Class path: <fpath>\t\tClass volume: <classVolume> LOC\t\tTotal Complexity: <totalCC>\t\tDuplicates: <dups.amt> hits (<precision(toReal(dups.amt)/dups.total*100, 3)> %)",
				fontBold(true));
}

// sub treemap on hover method that shows a dialog with unit name, unit size and the cyclomatic complexity of set unit
public FProperty onHover(str unitName, tuple[int amt, real pct] usize, tuple[int amt, real pct] cc){
	return mouseOver(box(text("Unit name: <unitName>\nUnit size: <usize.amt> LOC (<usize.pct>%)\nComplexity: <cc.amt> (<cc.pct>%)", fontBold(true)), resizable(false), grow(1.2)));
}

// Fill the ellipse with either white if the method is a testmethod, Chartreuse (green) if the method is tested or coral (orange) if the method has not been tested
public FProperty testCoverageFillColor(str fpath, str methodName, map[str, int] tCoverMetric){
	
	if ("<fpath>/<methodName>" notin tCoverMetric){
		return fillColor("white");
	} else if (tCoverMetric["<fpath>/<methodName>"] == 1){
		return fillColor("Chartreuse");
	} else {
		return fillColor("Coral");
	}
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




