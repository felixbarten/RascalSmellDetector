module detectors::RefusedBequest

import Prelude;
import String;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import metrics::LOC;
import metrics::CC;
import util::Reporting;
import util::Settings;

real avgLOC = 0.0;
real avgCC = 0.0;
real avgAMW = 0.0;
tuple[map[loc, tuple[int wmc, real amw]], int, int, real] complexity = <(), 0,0, 0.0>;
tuple[rel[loc,int], int,int,int,num] linesOfCode = <{}, 0,0,0,0>;
map[loc, set[int]] locMap = ();
map[loc, tuple[int wmc, real amw]] ccMap = ();
str prefix = "[RB]";

public void initialize(M3 model) {
	linesOfCode = calculateLOC(model);
	complexity = calculateClassesCC(model);
	
	avgLOC = toReal(linesOfCode[3]);
	avgCC = toReal(complexity[2]);
	locMap = toMap(linesOfCode[0]);
	ccMap = complexity[0];
	avgAMW = complexity[3];
	
	printCyclomaticComplexity(ccMap, complexity[1], printAll = false);
}

// detect RB using Lanza and Marinescu's metrics 
public bool detectRB(M3 model) {	
	// step 1: create AST from project.
	// step 2a: visit classes to see if they have a superclass. If not skip. 
	// Step 2b If they do have a superclass can we access it or is it a default library?
	// Step 3: perform analysis on parent and child. 
	initialize(model);
	println("<prefix> Detector starting for project");
	rel[loc, loc, bool] RBCandidates = {};
	list[loc] nonTrivialClasses = [];
	bool RB = false;
	
	println("<prefix> Creating AST");
	// loop through the extended classes. This satisfies the precondition step in 2a and 2b. 
	for(cls <- model.extends, classIsValid(cls)) {
		loc child = cls[0];
		loc parent = cls[1];
		
		bool simple = classIsNotSimple(child);
		bool bequest = classIgnoresBequest(model, child, parent);
		if(simple) {
			debug("<child> is a simple class");
			nonTrivialClasses += child;
		}
		RB = simple && bequest;
		RBCandidates += <child, parent, RB>;
	}
	println("Finished creating AST");
	

	println("<prefix> Number of RB candidates: <size(RBCandidates)> ");
	println("<prefix> Number of Simple classes: <size(nonTrivialClasses)>");
	return RB;
}

// cls must have a superclass. And superclass needs to be accessible within the project. 
bool classIsValid(tuple[loc, loc] classes) {
	return isFile(classes[0])  && isFile(classes[1]);
}

//
bool classIgnoresBequest(M3 model, loc child, loc parent) {
	// for debugging to make sure all the code paths are executed (overrides would be skipped if the first conditon is true otherwise).
	bool protected = parentHasProtectedMembers(model, parent);
	bool childBequest = childRefusesBequest();
	bool overrides = childHasFewOverrides(model, child);

	return (protected && childBequest) || overrides;
}

bool parentHasProtectedMembers(M3 model, loc parentLoc) { 
	int threshold = getProtectedMemberThreshold();
	// 1. loop through modifiers 2. find matches to parent loc 3. count occurences. 
	int count = 0;
	for (m <- model.modifiers, m[0].parent.path == parentLoc.path && m[1] == \protected()) {
		count += 1;
	}	
	return count > threshold;
}

bool childRefusesBequest(M3 model, loc child, loc parent) { 
	

	return false;
}

bool childHasFewOverrides(M3 model, loc child) { 
	int threshold = getBequestOverrideThreshold();
	str className = child.file; 
	str classPath = child.path;
	rel[loc, loc] overrides = {};
	// loop through overrides
	for (ov <- model.methodOverrides){ 	
		// compare whole path partial names give too many matches especially with certain naming conventions. 
		if(classPath == (ov[0].parent.path)){ 
			// do stuff here 
			overrides += ov; 
			// either filter more here or do it in another loop. 
		}
	}
	bool condition = size(overrides) > threshold;
	debug("[overrides] <child> has more overrides than threshold", condition); 
	
	return condition;
} 


// (functional complexity above average || class complexity is not lower than average). && Class size is above average. 
bool classIsNotSimple(loc cls) {
	return (funcComplexityAbvAvg(cls) || classComplexityAbvAvg(cls)) && classSizeAbvAvg(cls);
}

bool funcComplexityAbvAvg(loc cls) {
	checkIfClassHasValue(cls);
	
	bool condition = ccMap[cls].amw > avgAMW;
	debug("Class <cls.file> has an AMW higher than the avg. <ccMap[cls].amw> avg: <avgAMW>", condition);
	
	return condition;
}

bool classComplexityAbvAvg(loc cls) { 
	int clsCC = 0;
	checkIfClassHasValue(cls);
	clsCC = ccMap[cls].wmc;
	
	// debugging
	bool condition = clsCC > avgCC;
	if (condition) 	println("<cls> is more complex than avg: <condition>");
	return condition;
}

// are the locs from the extends the same ones are the ones from iterating over compilation units?
// they should be but are they? Needs a fallback method. 
bool classSizeAbvAvg(loc cls) {
	int clsLOC = 0;
	if (cls in locMap){
		//println("Class already has a loc value <max(locMap[cls])>");
		clsLOC = max(locMap[cls]);
	} else {
		debug("Class size value not found in lines of code");
		clsLOC = calculateLOCFromLocation(cls);
		debug("Calculated loc... <clsLOC>");
	}
	// debugging
	bool condition = clsLOC > avgLOC;
	if(condition) println("<cls> is above avg class size: <condition>");
	return condition;
}

void checkIfClassHasValue(loc cls) {
	if (cls notin ccMap){
		debug("Class was not found in map");
		// calc cc and add to the map.
		ccMap[cls] = calculateCCByLocation(cls);
	}
}

//Strip location to class name. 
str stripLocation(loc location) {
	loc locPath = location.parent; 
	list[str] paths = split("/", locPath.path);
	return last(paths);
}

str stripClassToName(loc location) {
	return location.file;
}