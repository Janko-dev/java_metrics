module Functions

import IO;
import List;
import String;
import Map;

// Eliminates singe line comments
public str trimSinglelineComments(str line) {
	//Regexp Search for // and remove comment (empty String is returned)
  	if(/^[\/]{2}/ := trim(line)) {
    	return "";
  	}
	
	//Strings Search for /* and */ and remove comment
  	int commentStart = findFirst(line, "/*");
  	int commentLast = findLast(line, "*/");
  	if(commentStart != -1 && commentLast != -1) {
    	return trim(substring(line, commentLast+1, size(line)-1));
  	}
  	return line;
}

// Eliminates javadoc, block starts with /** ends with */
public list[str] trimJavaDoc(list[str] lines) {
  	str startStr = "/**";
  	str endStr = "*/";
  	try {
    	container = zip([0..(size(lines))], lines); //zip makes a list of pairs from 2+ lists
    	tuple[int,int] commentStart = lazyFind(container, startStr);
    	tuple[int,int] commentEnd = lazyFind(container, endStr);
    	list[str] trim = deleteBetween(lines, commentStart, <commentEnd[0], commentEnd[1]+size(endStr)>);
    	return trimMultilineComments(trim);
  	} catch: return lines;
}

// Eliminates Multiple line comments, block starts with /* ends with */
public list[str] trimMultilineComments(list[str] lines) {
  	str startStr = "/*";
  	str endStr = "*/";
  	try {
    	container = zip([0..(size(lines))], lines); //zip makes a list of pairs from 2+ lists
    	tuple[int,int] commentStart = lazyFind(container, startStr);
    	tuple[int,int] commentEnd = lazyFind(container, endStr);
    	list[str] trim = deleteBetween(lines, commentStart, <commentEnd[0], commentEnd[1]+size(endStr)>);
    	return trimMultilineComments(trim);
  	} catch: return lines;
}

// Find pattern, Head and Tail recursive function like in Haskell
public tuple[int,int] lazyFind(lrel[int, str] container, str pattern) {
  	if([H, *T] := container) { //Head *Tail
    	if(contains(H[1], pattern) && !inString(H[1], pattern)) {
      		return <H[0], findFirst(H[1], pattern)>;
    	} else {
      		return lazyFind(T, pattern);
    	}
  	} else {
    	throw "Pattern not found";
  	}
}

// filter out lines that dont comply with the given function
public list[&T] filterEmpty(list[&T] vals, bool (str)func) {
  	return [ x | x <- vals, func(x)];
}

// Remove lines betweek start and end block
public list[str] deleteBetween(list[str] lines, tuple[int, int] from, tuple[int, int] til) {
  	if(from[0] == til[0]) {
    	lines[from[0]] = deleteBetween(lines[from[0]], from[1], til[1]);
    	return lines;
  	} else {
    	str line = lines[from[0]];
    	lines[from[0]] = deleteBetween(line, from[1], size(line));
    	return deleteBetween(lines, <from[0]+1, 0>, til);
  	}
}

// Remove charachters in line between start and end index
public str deleteBetween(str line, int startIndex, int endIndex) {
  	return substring(line, 0, startIndex) + substring(line, endIndex, size(line));
}

// Check given pattern is not commented out by (")
public bool inString(line, pattern) {
  	foc = findFirst(line, "\"");
  	soc = findLast(line, "\"");
  	if(foc != soc && foc != -1 && soc != -1) {
    	sub = substring(line, foc, soc);
    	return contains(sub, pattern);
  	}
  	return false;
}

// percentage calculation
public real percentage(real part, int total) {
  	return part / total * 100.0;
}

//returns the risks maps with the percentage of the total for each level
public map[str, real] riskPercentages(map[str, real] risks, int totalLoc) {
  	// Calculates percentages for each risk level.
  	for(str key <- domain(risks)) {
    	risks[key] = percentage(risks[key], totalLoc);
  	}
  	return risks;
}

//Output Unit size info
public void resultsPrinter(map[str, real] riskLevels) {
  	real low = riskLevels["low"];
  	real moderate = riskLevels["moderate"];
  	real high = riskLevels["high"];
  	real veryHigh = riskLevels["veryHigh"];

  	println("Low:\t\t<low>");
  	println("Moderate:\t<moderate>");
  	println("High:\t\t<high>");
  	println("Very High:\t<veryHigh>\n");
}

// print key-value pairs of the aggregated scores of the metrics
public void scorePrinter(map[str, str] scores) {
  	for (<str name, str score> <- toRel(scores)){
  		println("<name>: <score>");
  	}
  	println();
}

// Aggregate scores into one score
public str aggregateScores(list[str] scores){
	// -- - o + ++
	// 1  2 3 4 5
	map[str, int] encoder = ("--": 1, "-": 2, "o": 3, "+": 4, "++": 5);
	list[int] encoded = [ encoder[sc] | sc <- scores];

	int mean = sum(encoded)/size(scores);
	return invertUnique(encoder)[mean];
}

// Eliminate comments and empty lines
public list[str] trimLoc(loc content) {
  	list[str] objectContent = readFileLines(content);
	// Replace Multiline comment with empty
  	objectContent = trimMultilineComments(objectContent);
	// Replace javadoc with empty
  	objectContent = trimJavaDoc(objectContent);
	// Replace single line comments with empty
  	objectContent = mapper(objectContent, trimSinglelineComments);
	// Filter Empty
  	objectContent = filterEmpty(objectContent, bool (str f) { return size(trim(f)) != 0; });
  	return objectContent;
}