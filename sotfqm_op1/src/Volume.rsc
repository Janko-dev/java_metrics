module Volume

import IO;
import String;
import List;
import Set;
import util::FileSystem;
import Functions;

// Calulates Volume of project
public void volume(loc m3) {
  int totalLoc = sum([linesPerFile(f)| /file(f) <- crawl(m3), f.extension == "java"]);
  println("Lines of Code: <totalLoc>");
  print("Score: ");
// SIG Values from A practical Model for Measuring Maintainability  
  if(totalLoc <= 66000) {
    print("++");
  } else if(totalLoc <= 246000) {
    print("+");
  } else if(totalLoc <= 665000) {
    print("o");
  } else if(totalLoc <= 1310000) {
    print("-");
  } else {
    print("--");
  }
  println();
}

// Calculates number of lines per file
public int linesPerFile(loc file) {
  return size(trimFile(file));
}

// Eliminate comments and empty lines
public list[str] trimFile(loc file) {
  list[str] fileContent = readFileLines(file);
// Replace Multiline comment with empty
  fileContent = trimMultilineComments(fileContent);
// Replace single line comments with empty
    fileContent = mapper(fileContent, trimSinglelineComments);
// Filter Empty
    fileContent = filterEmpty(fileContent, bool (str f) { return size(trim(f)) != 0; });
  return fileContent;
}
