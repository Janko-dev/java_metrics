module Volume

import IO;
import String;
import List;
import Set;
import util::FileSystem;
import Functions;

// Calulates Volume of project
public tuple[int, str] volume(loc m3) {
  int totalLoc = sum([linesPerFile(f)| /file(f) <- crawl(m3), f.extension == "java"]);
  println("Lines of Code: <totalLoc>");
  
  tuple[int lines, str score] vol = <0, "">;
// SIG Values from A practical Model for Measuring Maintainability  
  vol.lines = totalLoc;
  if(totalLoc <= 66000) {
    vol.score = "++";
  } else if(totalLoc <= 246000) {
     vol.score = "+";
  } else if(totalLoc <= 665000) {
       vol.score = "o";
  } else if(totalLoc <= 1310000) {
       vol.score = "-";
  } else {
       vol.score = "--";
  }
  return vol;
}

// Calculates number of lines per file
public int linesPerFile(loc file) {
  return size(trimLoc(file));
}
