module metrics::LOC

import Prelude;
import util::Math;
import util::Reporting;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

str prefix = "[LOC]";

// Returns a tuple with a relation of [class, loc], total LOC, blank lines and comments, average LOC
public tuple[rel[loc, int],int,int,int,real] calculateLOC(M3 model) {
	rel[loc,int] classLOC = {};
	list[tuple[int, int, int]] LOCContainer = [];
	println("<prefix> Looping through compilation units to calculate LOC");
	
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit" && 
		(cu[1].scheme == "java+class" || cu[1].scheme == "java+interface")) {
		
		LOCval = getLOC(cu[1]);
		LOCContainer += LOCval;
		classLOC += <cu[1], LOCval[0]>;
	}	
	println("<prefix> Finished calculating LOC");
	totalLOC = getTotalLOC(LOCContainer);
	
	return <classLOC, totalLOC[0], totalLOC[1], totalLOC[2], getAvgLOC(totalLOC[0], size(LOCContainer))>; 
}

public real getAvgLOC(int totalLOC, int numberOfFiles) {
	return toReal(totalLOC) / toReal(numberOfFiles);
}

// duplication unfortunately. 
// detector needs avg size but it doesn't clearly specify if it's with or without interfaces?.
public real calculateAvgClassLOC(M3 model) {
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
public tuple[int locNum, int blank, int comments] getLOC(loc location) {
	int LOC = 0;
	int blankLines = 0;
	int comments = 0;
	bool incomment = false; 
	
	srcLines = readFileLines(location); 	
	for (line <- srcLines) {	
		if (/^\s*\/\/\s*\w*/ := line) {
			debug("single line comment: <line>");
			comments += 1;
		} else if (/((\s*\/\*[\w\s]+\*\/)+[\s\w]+(\/\/[\s\w]+$)*)+/ := line) {
			debug("multiline and code intertwined: <line>");
			LOC += 1;
			
		}else if (/^\s*\/\*\*?[\w\s\?\@]*\*\/$/ := line) {
			debug("single line multiline:  <line>");
			comments += 1;
		}  else if (/\s*\/\*[\w\s]*\*\/[\s\w]+/ := line) {
				debug("multiline with code: <line>");
			LOC += 1;
		}	else if (/^[\s\w]*\*\/\s*\w+[\s\w]*/ := line) {
			// end of multiline + code == loc
			debug("end of multiline + code:  <line>");
			
			incomment = false; 
			LOC += 1;
		}	else if (/^\s*\/\*\*?[^\*\/]*$/ := line){
			incomment = true;
			comments += 1;
			debug("start multiline comment:  <line>");
				
		} else if (/\s*\*\/\s*$/ := line){
			debug("end multiline comment: <line>");
			comments += 1;
			incomment = false;
				
		} else if (/^\s*$/ := line) {
			blankLines += 1;
		} else {
			if (!incomment) {
				debug("code: <line>");
				LOC += 1;
			} else {
				debug("comment: <line>");
				comments += 1;
				}
			}
			
		}
	debug("Results for file: <location>");
	debug("Lines of Code: <LOC>");
	debug("Commented lines: <comments>");
	debug("Blank lines: <blankLines>");
	
	return <LOC, blankLines, comments>;
}

public int calculateLOCFromLocation(loc location) {
	LOCval = getLOC(location);

	return LOCval[0];
}