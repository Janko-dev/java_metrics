module Clones

import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;

import Volume;
import String;
import DateTime;

import util::Resources;
import List;
import Set;
import IO;
import Functions;

alias ProjectMap = map[loc file, list[str] strContent];
alias strProjectMap = map[loc file, str Content];

//Store all java files in a map, with file contents as a list of strings
//Used to split each file in blocks of 6 lines of code
ProjectMap projectContents = ();

//Store all java files in a map, with file contents as a string
//Used to search for a particular code block in all files
strProjectMap strProjectContents = ();

//Reads java files from project
set[loc] readJavaFiles(loc project) {
   Resource r = getProject(project);
   return { a | /file(a) <- r, a.extension == "java" };
}


//Finds clones in a projoject
public str findClones(loc m3, bool showoutput){

  //datetime startTime = now();
  set[loc] allFiles = readJavaFiles(m3);
 
  projectContents = ( a:trimLoc(a) | a <- allFiles );
  
  strProjectContents = ( a:toString(trimLoc(a)) | a <- allFiles );
 
  int volume = sum([size(trimLoc(f)) | loc f <- allFiles]);
  real totalClones = 0.0;

  for(fileContent <- projectContents){
//Process each java file in project
  	 totalClones += findclone(fileContent, showoutput);	
  }
 
  real duplication = totalClones / 2 / volume * 100;
  
  println("Duplication: <totalClones/volume * 100>\n"); //how many blocks of 6 lines will be compared with the rest of the files (min 1 match, itself)	
  //println(now());
  
  return rating(duplication);
}

public str rating(real dups){
	if (dups < 3) {
		return "++";
	} else if (dups >= 3 && dups < 5) {
		return "+";
	} else if (dups >= 5 && dups < 10) {
		return "o";
	} else if (dups >= 10 && dups < 20) {
		return "-";
	} else {
		return "--";
	}
}

// Split file content into blocks
list[str] makeBlocks(int blockSize, list[str] content){
	
	list[str] blocks = [];
	while( size(content)>blockSize ){
	 	codeBlock = head(content,blockSize);
	 	content = tail(content, (size(content) - 1));
	 	strCodeBlock = replaceLast(toString(codeBlock), "]" , "");
	 	strCodeBlock = replaceFirst(strCodeBlock, "[" , "");
		strCodeBlock = substring(strCodeBlock, 1, size(strCodeBlock)-1);
	 //Add prepared block to list of blocks for this file	 		
	 	blocks = blocks + strCodeBlock;
 	}
 return blocks;
}

// Print clone information
void printInfo(loc target, loc source, str sampleCode){
    println("target:<target>");
	println("source:<source>");
	println("sampleCode:<sampleCode>");
}

// String comparison of each given block with the content collection
int searchInFiles(list[str] blocks, loc source, bool showoutput){

    int total = 0;
    str sampleCode = "";
 	for(target <- strProjectContents){
 	 	int matches = 0;
 	 	sampleCode = "";
 		targetContent = strProjectContents[target];
		for(block <- blocks){
	    	matches += size(findAll(targetContent, block));
	    	if (matches >= 1 && sampleCode == ""){
	    		sampleCode = block;
	    	}
	    }
	    if(target != source){
			if (matches > 0){
				total += matches; 
	 		} 	    
	    }else{	
			if (matches > size(blocks)){
				total += matches - size(blocks); 
	 		}
 		}
 		if(showoutput){
 			printInfo(target, source, sampleCode); 
 		}		
 	}
 	return total;
}

//Find Clones for the contents of the given file
 int findclone(loc file, bool showoutput){

	 int total = 0;
	
	 list[str] filecontent = projectContents[file];
	
	// make blocks of 6 lines and compare with all files, we get at least 1 match 
	 list[str] fileBlocks = makeBlocks(6, filecontent);
	 
	 total = searchInFiles(fileBlocks, file, showoutput);
	 
	// when done, remove proccessed file from collection (prevents double detection, improves performance)
	 strProjectContents -= (file : "");
	 return total;
}

