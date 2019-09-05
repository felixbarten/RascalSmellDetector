module metrics::LOC

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public tuple[int,int,int] calculateLOC(M3 model) {
	
	rel[str,int] locs;
	rel[loc,int] locs2;
	list[tuple[int, int, int]] LOCcontainer = [];
	println("Looping through compilation units for calculating Lines of Code");
	
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit") {
	
		//println(cu[0]);
		LOCval = getLOC(cu[0], false);
		println(LOCval);
		// append tuples 
		LOCcontainer += LOCval;
	}	
	println("calculating lines of code done");
	
	return getTotalLOC(LOCcontainer); 
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
public tuple[int locNum, int blank, int comments] getLOC(loc location, bool debug) {
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