module detectors::RefusedBequest

import IO;
import List;
import Set; 
import Relation;
import Map;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import metrics::LOC;
import metrics::CC;
import util::Reporting;
import util::Settings;

int avgLOC = 0; 
int avgCC = 0;
tuple[map[loc, tuple[int wmc, real amw]], int, int] complexity = <(), 0,0>;
tuple[rel[loc,int], int,int,int,num] linesOfCode = <{}, 0,0,0,0>;
map[loc, set[int]] locMap = ();
map[loc, tuple[int wmc, real amw]] ccMap = ();

public void initialize(M3 model) {
	linesOfCode = calculateLOC(model);
	complexity = calcClassCC(model);
	
	avgLOC = linesOfCode[3];
	avgCC = complexity[2];
	locMap = toMap(linesOfCode[0]);
	ccMap = complexity[0];
	
	printCyclomaticComplexity(ccMap, complexity[1], printAll = true);

}

// detect RB using Lanza and Marinescu's metrics 
public bool detectRB(M3 model) {	
	// step 1: create AST from project.
	// step 2a: visit classes to see if they have a superclass. If not skip. 
	// Step 2b If they do have a superclass can we access it or is it a default library?
	// Step 3: perform analysis on parent and child. 
	initialize(model);
	println("[RB] Detector starting for project");
	rel[loc, loc, bool] RBCandidates = {};
	bool RB = false;
	
	println("Creating AST");
	// loop through the extended classes. This satisfies the precondition step in 2a and 2b. 
	for(cls <- model.extends, clsValid(cls) == true) {
		//println(cls);
		loc child = cls[0];
		loc parent = cls[1];
		
		bool simple = classIsNotSimple(child);
		bool bequest = classIgnoresBequest(child);
		if(simple) println("<child> is a simple class");
		RB = simple && bequest;
		RBCandidates += <child, parent, RB>;
	}
	println("Finished creating AST");
	

	println("Number of RB candidates: <size(RBCandidates)> ");
	//println("<linesOfCode[0]>");
	return RB;
}

// cls must have a superclass. And superclass needs to be accessible within the project. 
public bool clsValid(tuple[loc, loc] classes) {
	return isFile(classes[0])  && isFile(classes[1]);
}

//
public bool classIgnoresBequest(loc cls) {
	return (parentHasProtectedMembers() && childRefusesBequest()) || childHasFewOverrides();
}

public bool parentHasProtectedMembers() { 
	return false;
}

public bool childRefusesBequest() { 
	return false;
}
public bool childHasFewOverrides() { 
	int threshold = getBequestOverrideThreshold();
	return false;
} 


// (functional complexity above average || class complexity is not lower than average). && Class size is above average. 
public bool classIsNotSimple(loc cls) {
	return (funcComplexityAbvAvg(cls) || clsComplexityAbvAvg(cls)) && clsSizeAbvAvg(cls);
}

public bool funcComplexityAbvAvg(loc cls) {
	// get AMW
	if (cls in ccMap && ccMap[cls].wmc > 50) {
		println("AMW: <ccMap[cls].amw>");
		println("CLS: <cls>");
	}

	return true;
}

public bool clsComplexityAbvAvg(loc cls) { 
	int clsCC = 0;
	if (cls notin ccMap){
		//println("Class already has a complexity value <ccMap[cls]>");
		println("Class was not found in complexity map");
		// calc cc; 
		ccMap[cls] = calculateCCByLocation(cls);
		println("Calculated cc... <ccMap[cls].wmc>");
	}
	clsCC = ccMap[cls].wmc;
	
	// debugging
	bool condition = clsCC > avgCC;
	if (condition) 	println("<cls> is more complex than avg: <condition>");
	return condition;
}

// are the locs from the extends the same ones are the ones from iterating over compilation units?
// they should be but are they? Needs a fallback method. 
public bool clsSizeAbvAvg(loc cls) {
	int clsLOC = 0;
	if (cls in locMap){
		//println("Class already has a loc value <max(locMap[cls])>");
		clsLOC = max(locMap[cls]);
	} else {
		println("Class size value not found in lines of code");
		clsLOC = calculateLOCByLocation(cls);
		println("Calculated loc... <clsLOC>");
	}
	// debugging
	bool condition = clsLOC > avgLOC;
	if(condition) println("<cls> is above avg class size: <condition>");
	return condition;
}