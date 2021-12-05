module Clones

import lang::java::m3::AST;
import lang::java::m3::Core;
import util::FileSystem;
import Volume;
import String;
import DateTime;
import Map;
import util::Resources;
import List;
import Set;
import IO;
import Functions;


alias ProjectMap = map[loc file, list[str] strContent];
alias strProjectMap = map[loc file, str Content];

ProjectMap projectContents = ();
strProjectMap strProjectContents = ();

set[loc] javaBestanden(loc project) {
   Resource r = getProject(project);
   return { a | /file(a) <- r, a.extension == "java" };
}

public void findClones(loc m3){
  
  set[loc] bestanden = javaBestanden(m3);
 
  projectContents = ( a:trimLoc(a) | a <- bestanden );
  
  strProjectContents = ( a:toString(trimLoc(a)) | a <- bestanden );
	 
  datetime startTime = now();
  println("start");
  println(startTime);
  
  int totalClones = 0;

  for(fileContent <- projectContents){
//Process each file in project
  	 totalClones += findclone2(fileContent);	
  }
 
  totalClones = totalClones / 2;
  println("Clones found:");
  println(totalClones); //how many blocks of 6 lines will be compared with the rest of the files (min 1 match, itself)	
  println(now());
}


 int findclone2(loc file){
// Get all files and store them as a List of strings 

 int total = 0;
 str sampleCode = "";

 list[str] filecontent = projectContents[file];
 list[str] fileBlocks = [];
// make blocks of 6 lines and compare with all files, we get at least 1 match 
 while( size(filecontent)>6 ){
 	codeBlock = head(filecontent,6);
 	filecontent = tail(filecontent, (size(filecontent) - 1));
 	strCodeBlock = replaceLast(toString(codeBlock), "]" , "");
 	strCodeBlock = replaceFirst(strCodeBlock, "[" , "");
	strCodeBlock = substring(strCodeBlock, 1, size(strCodeBlock)-1);
 //Add prepared block to list of blocks for this file	 		
 	fileBlocks = fileBlocks + strCodeBlock;
 }
 
 if (size(findAll(toString(fileBlocks), "SSCallableStatement"))>0){
 	int breaker = 0;
 }
 	for(sourcefile <- strProjectContents){
 	 	int matches = 0;
 	 	sampleCode = "";
 		sourceContent = strProjectContents[sourcefile];
//		matches = checkFile(codeBlock, strSource);
		for(block <- fileBlocks){
	    	matches += size(findAll(sourceContent, block));
//	    	if (matches > 100){
//	    		sourceContent = replaceAll(sourceContent, block, "");
//	    	}
	    	if (matches >= 1 && sampleCode == ""){
	    		sampleCode = block;
	    	}
	    }
	    if(sourcefile != file){
			if (matches > 0){
			    println("target:<sourcefile>");
				println("source:<file>");
				println("sampleCode:<sampleCode>");
				total += matches; 
	 		} 	    
	    }else{	
			if (matches > size(fileBlocks)){
			    println("target:<sourcefile>");
				println("source:<file>");
				println("sampleCode:<sampleCode>");
				total += matches - size(fileBlocks); 
	 		}
 		} 		
// 		matches += compareBlock(codeBlock, file);
 	}
 	return total;
}

