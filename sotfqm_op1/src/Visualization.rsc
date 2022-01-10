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

// aliases
alias UnitCC = lrel[str uName, int uSize, int cc];

// global vars
Figure dataView = box(fillColor(rgb(0, 0, 0, 0.0)));
bool selected = false;

// point generator
Figure point(num x, num y) = ellipse(shrink(0.05), fillColor("red"), align(x, y));

public void run(){
	
	//loc path = |project://sotfqm_op1/data/smallsql.txt|;
	loc path = |project://sotfqm_op1/data/hsqldb.txt|;
	
	renderTreemap(path);
	//renderScatterplot(path);
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

public void renderTreemap(loc path){

	map[str, UnitCC] ccMetric = readTextValueFile(#map[str, UnitCC], path);
	
	UnitCC mapContent = joinMapContent(ccMetric);
	int maxCC = max(mapContent.cc);
	int maxUnit = max(mapContent.uSize);
	
	list[Figure] tmap = [ 
		box(
			treemap([box(area(s), fillColor(lerpColor(cc, maxCC))) | <_, int s, int cc> <- cont], shrink(0.9)), 
			area(valueMapper(sum([0]+cont.uSize), 1, maxUnit, 10, 30)),
			onClickElement(fpath, cont, maxCC)
			//fillColor(arbColor())
			)
	 	| <str fpath, UnitCC cont> <- toList(ccMetric)];
	
	render(computeFigure(Figure () {return overlay([treemap(tmap), dataView]);}));
}

public FProperty onClickElement(str fpath, UnitCC content, int maxCC){
	return onMouseDown(bool (int _, map[KeyModifier,bool] _) {
		
		if (!selected) {
			
			list[Figure] tmap = [box(
				area(s), 
				fillColor(lerpColor(cc, maxCC)),
				onHover(name, s, cc)) | <str name, int s, int cc> <- content];
			
			dataView = box(
				vcat(
					[
						text("Class path: <fpath>\t\t\tTotal unit size: <sum(content.uSize)> LOC\t\t\tTotal Complexity: <sum(content.cc)>"), 
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

// join tuples of map into list
public lrel[str, int, int] joinMapContent(map[str, lrel[str, int, int]] input){
	return reducer(range(input), lrel[str, int, int] (lrel[str, int, int] a, lrel[str, int, int] b) {return a + b;}, []);
}

// maps a numeric value n from one number space (start1 - stop1) to another number space (start2 - stop2) 
// by normalizing the value first and then applying the given number space
private real valueMapper(num n, num start1, num stop1, num start2, num stop2) {
	return ((toReal(n)-toReal(start1))/(toReal(stop1)-toReal(start1)))*(toReal(stop2)-toReal(start2))+toReal(start2);
}

// linearly interpolate between two colors given a number n and the max value for n
private Color lerpColor(int n, int maxN){
	return interpolateColor(color("PaleTurquoise"), color("Teal"), valueMapper(n, 0.0, maxN, 0.0, 1.0));
}




