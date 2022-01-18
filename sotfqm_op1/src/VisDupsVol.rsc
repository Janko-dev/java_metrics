module VisDupsVol

import IO;
import ValueIO;
import List;
import Map;
import Relation;
import Set;
import util::Math;
import analysis::graphs::Graph;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import vis::Figure;
import vis::Render;
import vis::KeySym;

loc tmpSize = |project://sotfqm_op1/data/hsqldb_sizes.txt|;
loc tmpClones = |project://sotfqm_op1/data/hsqldb_clones.txt|;

//loc tmpSize = |project://sotfqm_op1/data/smallsql_sizes.txt|;
//loc tmpClones = |project://sotfqm_op1/data/smallsql_clones.txt|;

map[loc file, int size] fileSizes = ();
map[loc file, int clones] fileClones = ();

void readCache() {
   fileSizes = readTextValueFile(#map[loc, int], tmpSize);
   fileClones = readTextValueFile(#map[loc, int], tmpClones);
}

FProperty FillMyColor(loc s){
	real r = toReal(fileClones[s]) / 10;
	return fillColor(gray(0.5, r));
}

FProperty popup(str S, loc s){
 return mouseOver(box(text(S + " Clones:" + toString(fileClones[s])), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}


public void visDupsVol() {
   readCache();
   Figure jabberTreemap2 = treemap([ box(text(""),area(n),FillMyColor(s), popup(s.path + " ,Size:" + toString(n), s)) | <s,n> <- toRel(fileSizes) ]);
   render("Application treemap", jabberTreemap2);
}
