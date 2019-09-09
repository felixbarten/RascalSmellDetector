module metrics::LOC

import Prelude;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public tuple[rel[loc, int],int,int,int,real] calculateLOC(M3 model) {
	
	rel[loc,int] locs = {};
	list[tuple[int, int, int]] LOCContainer = [];
	println("Looping through compilation units for calculating Lines of Code");
	
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit" && 
		(cu[1].scheme == "java+class" || cu[1].scheme == "java+interface")) {
		LOCval = getLOC(cu[1]);
		// append tuples 
		LOCContainer += LOCval;
		locs += <cu[1], LOCval[0]>;
	}	
	println("calculating lines of code done");
	totalLOC = getTotalLOC(LOCContainer);
	
	return <locs, totalLOC[0], totalLOC[1], totalLOC[2], getAvgLOC(totalLOC[0], size(LOCContainer))>; 
}

public real getAvgLOC(int totalLOC, int numberOfFiles) {
	return toReal(totalLOC) / toReal(numberOfFiles);
}

// duplication unfortunately. 
// detector needs avg size but it doesn't clearly specify if it's with or without interfaces?.
public num calculateAvgClassLOC(M3 model) {
	list[tuple[int, int, int]] LOCcontainer = [];	
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit" && 
		cu[1].scheme == "java+class") {
		LOCval = getLOC(cu[0]);
		LOCcontainer += LOCval;
	}	
	totalLOC = getTotalLOC(LOCcontainer);
	
	return getAvgLOC(totalLOC[0], size(LOCcontainer)); 
}

// There are some arbitrary keywords such as loc. The program will stop syntax highlighting if this is the case (without visible IDE errors).
public tuple[int locNum, int blank, int comments] getTotalLOC(list[tuple[int locNum, int blank, int comments]] locs){
	tuple[int locNum, int blank, int comments] totalLOC = <0,0,0>;
	
	// Surely this can be done with like a map function 
	for (subLOC <- locs) { 
		totalLOC.locNum += subLOC.locNum;
		totalLOC.blank += subLOC.blank;
		totalLOC.comments += subLOC.comments;
	}
	
	return totalLOC;
}

// placeholder loc code.
public tuple[int locNum, int blank, int comments] getLOC(loc location, bool debug = false) {
	int LOC = 0;
	int blankLines = 0;
	int comments = 0;
	bool incomment = false; 
	
	srcLines = readFileLines(location); 	
	for (line <- srcLines) {	
		if (/^\s*\/\/\s*\w*/ := line) {
			if (debug)
				println("single line comment: <line>");
			comments += 1;
		} else if (/((\s*\/\*[\w\s]+\*\/)+[\s\w]+(\/\/[\s\w]+$)*)+/ := line) {
			if (debug) {
				println("multiline and code intertwined: <line>");
			}
			LOC += 1;
			
		}else if (/^\s*\/\*\*?[\w\s\?\@]*\*\/$/ := line) {
			if (debug)
				println("single line multiline:  <line>");
			comments += 1;
		}  else if (/\s*\/\*[\w\s]*\*\/[\s\w]+/ := line) {
			if (debug)
				println("multiline with code: <line>");
			LOC += 1;
		}	else if (/^[\s\w]*\*\/\s*\w+[\s\w]*/ := line) {
			// end of multiline + code == loc
			if (debug) {
				println("end of multiline + code:  <line>");
			}
			incomment = false; 
			LOC += 1;
		}	else if (/^\s*\/\*\*?[^\*\/]*$/ := line){
			incomment = true;
			comments += 1;
			if (debug)
				println("start multiline comment:  <line>");
				
		} else if (/\s*\*\/\s*$/ := line){
			if (debug)
				println("end multiline comment: <line>");
			comments += 1;
			incomment = false;
				
		} else if (/^\s*$/ := line) {
			blankLines += 1;
		} else {
			if (!incomment) {
				if (debug)
					println("code: <line>");
				LOC += 1;
			} else {
				if (debug)
					println("comment: <line>");
				comments += 1;
				}
			}
			
		}
	if (debug) {
		println("Results for file: <location>");
		println("Lines of Code: <LOC>");
		println("Commented lines: <comments>");
		println("Blank lines: <blankLines>");
	}
	return <LOC, blankLines, comments>;
}

public int calculateLOCByLocation(loc location) {
	LOCval = getLOC(location);

	return LOCval[0];
}