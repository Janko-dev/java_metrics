module Volume

import IO;
import String;
import List;
import Set;
import util::FileSystem;
import Functions;

// Calulates Volume of project
public str volume(loc m3) {
  int totalLoc = sum([linesPerFile(f)| /file(f) <- crawl(m3), f.extension == "java"]);
  println("Lines of Code: <totalLoc>");
  
// SIG Values from A practical Model for Measuring Maintainability  
  if(totalLoc <= 66000) {
    return "++";
  } else if(totalLoc <= 246000) {
    return "+";
  } else if(totalLoc <= 665000) {
    return "o";
  } else if(totalLoc <= 1310000) {
    return "-";
  } else {
  	return "--";
  }
}

// Calculates number of lines per file
public int linesPerFile(loc file) {
  return size(trimLoc(file));
}
