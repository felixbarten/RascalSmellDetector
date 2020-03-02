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
import util::DataStorage;
import analysis::graphs::Graph;

real avgLOC = 0.0;
real avgCC = 0.0;
real avgAMW = 0.0;
int totalCC = 0;
int totalLOC = 0;
map[loc, set[int]] locMap = ();
map[loc, tuple[int wmc, real amw]] ccMap = ();
str prefix = "[RB]";
bool useMetrics = false;


// INITIALIZE 
public void initialize(M3 model) {
	output("<prefix> Initializing RB detector...");
	setGlobalVars(calculateLOC(model), calculateClassesCC(model));
}

public void initialize(M3 model, 
		tuple[rel[loc,int],int,int,int,real] LOC,
		tuple[map[loc, tuple[int wmc, real amw]], int, int, real] CC) {
	setGlobalVars(LOC, CC);
	output("<prefix> RB detector state restored.");
}

void setGlobalVars(tuple[rel[loc,int],int,int,int,real] LOC,
		tuple[map[loc, tuple[int wmc, real amw]], int, int, real] CC) {
	totalLOC = LOC[1];
	totalCC = CC[1];
	avgLOC = toReal(LOC[4]);
	avgCC = toReal(CC[2]);
	locMap = toMap(LOC[0]);
	ccMap = CC[0];
	avgAMW = CC[3];
	useMetrics = getUseMetricsAverages();
	
	printLinesOfCode(LOC[0], totalLOC, avgLOC);
	printCyclomaticComplexity(ccMap, totalCC, printAll = false);
}

// DETECTION

// detect RB using Lanza and Marinescu's metrics 
public rel[loc,loc,bool] detectRB(M3 model, loc project, bool processed = false) {	
	// step 1:  Create AST from project.
	// step 2a: Visit classes to see if they have a superclass. If not skip. 
	// Step 2b  If they do have a superclass can we access it or is it a default library?
	// Step 3:  Perform analysis on parent and child. 

	if(!processed) {
		initialize(model);
	}
	// skip if disabled.
	if(!getRBEnabled()) {
		addProjectToReport(project, totalLOC, totalCC, "disabled");
		return {};
	}
	rel[loc,loc,bool] detectedRBClasses = {};
	rel[loc,loc,bool] RBCandidates = {};
	list[loc] nonTrivialClasses = [];
	bool RB = false;
	N = now();
	int count = 0;
	output("<prefix> Detecting Refused Bequest...");
	// loop through the extended classes. This satisfies the precondition step in 2a and 2b. 
	for(cls <- model.extends, classIsValid(cls)) {
		loc child = cls[0];
		loc parent = cls[1];
		// this step needs to be executed anyway so barely any performance loss for logging non-trivial classes.
		bool notSimple = classIsNotSimple(model, child);
		if(notSimple) {		
			debug("<child> is not a simple class");
			nonTrivialClasses += child;
		}
		// crucial for performance to only perform second calculation if class is not simple (3x the processing time without(or more)
		RB = notSimple && classIgnoresBequest(model, child, parent);
		tuple[loc,loc,bool] temp =<child, parent, RB>;
		
		if(RB) {
			detectedRBClasses  += temp;
			debug("RB: <temp>");
		}
		count += 1;
		printProgress(count, N);
	}
		
	output("<prefix> Number of RB candidates: <count> ");
	output("<prefix> Number of Simple classes: <size(nonTrivialClasses)>");
	output("<prefix> Number of RB positive classes: <size(detectedRBClasses)> ");
	output("<prefix> Finished detecting Refused Bequest in <convertIntervalToStr(N)>");
	
	printRB(detectedRBClasses, nonTrivialClasses);
	
	storeInformation(model, processed);

	addProjectToReport(project, totalLOC, totalCC, size(detectedRBClasses));
	
	return detectedRBClasses;
}

//use processed data
rel[loc,loc,bool] detectRB(M3 model, 
		loc project, 
		tuple[rel[loc,int],int,int,int,real] LOC,
		tuple[map[loc, tuple[int wmc, real amw]], int, int, real] CC) {
	initialize(model, LOC, CC);
	return detectRB(model, project, processed = true);
}


void printProgress(int count, datetime N){
	if(count % 250 == 0) {
		output("<prefix> Processed <count> classes");
	}
	if(count % 2000 == 0) {
		output("<prefix> RB detector has been running: <convertIntervalToStr(N)>");
	}
}

void storeInformation(M3 model, bool processed) {
	if(!processed) {
		storeModel(model);
	}
}


// Cls must have a superclass and superclass needs to be accessible within the project. 
bool classIsValid(tuple[loc, loc] classes) {
	return isFile(classes[0])  && isFile(classes[1]);
}

// (functional complexity above average || class complexity is not lower than average). && Class size is above average. 
// (AMW > AVG || WMC > AVG ) && NOM > AVG
bool classIsNotSimple(M3 model, loc cls) {
	return (funcComplexityAbvAvg(cls) || classComplexityAbvAvg(cls)) && classSizeAbvAvg(model, cls);
}


// (NProtM > FEW && BUR < 0.33 ) || BOvR < 0.33
bool classIgnoresBequest(M3 model, loc child, loc parent) {
	return (parentHasMoreThanAFewProtectedMembers(model, parent) && childRefusesBequest(model, child, parent)) || childHasFewOverrides(model, child);
}

// NProtM > FEW 
bool parentHasMoreThanAFewProtectedMembers(M3 model, loc parent) { 
	int threshold = getProtectedMemberHighThreshold();
	return getNProtM(model, parent) > threshold;
}

// return NProtM
int getNProtM(M3 model, loc parent) {
	int NProtM = 0;
	//compare paths instead of locations and check if the modifier is protected. 
	for (m <- model.modifiers, m[0].parent.path == parent.path && m[1] == \protected()) {
		NProtM += 1;
	}
	return NProtM;
}

// return protected members
list[loc] getNProtMList(M3 model, loc parent) {
	list[loc] NProtM = [];
	//compare paths instead of locations and check if the modifier is protected. 
	for (<location, modifier> <- model.modifiers, location.parent.path == parent.path && modifier == \protected()) {
		NProtM += location;
	}
	return NProtM;
}


// BUR < 0.33
bool childRefusesBequest(M3 model, loc childLoc, loc parentLoc) { 
	// calculate BUR: Base Class Usage Ratio.
	// "The number of inheritance-specific members used by the measured class,
	// divided by the total number of inheritance-specific members from the base
	// class"
	int usedMembers = 0;
	list[loc] parentMemberLocs = getNProtMList(model, parentLoc);
	int parentMembers = size(parentMemberLocs);
	rel[loc, loc] foundRelations = {};
	int memberCount = 0;
		
	// loop through field access and method invoc. 
	//  Check if this class is the start point and check if the end point is one of the protected parent members. 
	for (<from, to> <- model.fieldAccess, 
			from.parent.path == childLoc.path
			&& to in parentMemberLocs
			&& isFile(to)) {
		memberCount += 1;
		foundRelations += <from, to>;
	}
	
	for (<from, to> <- model.methodInvocation, 
			from.parent.path == childLoc.path 
			&& to in parentMemberLocs
			&& isFile(to)) {		
		memberCount += 1;
		foundRelations += <from, to>;
	}
		
	real ratio = 0.0;
	// prevent div/0 parent may genuinely be 0. 
	if (parentMembers > 0) {
		ratio = toReal(memberCount) / toReal(parentMembers);
	} 
		
	bool condition = ratio < 0.33;
	debug("<childLoc> refuses bequest: <condition>, <ratio>");
	return condition;
}

// BOvR < 0.33. 
bool childHasFewOverrides(M3 model, loc child) { 
	int highThreshold = getBequestHighOverrideThreshold();
	int lowThreshold = getBequestLowOverrideThreshold();
	rel[loc,loc] overridesList = getClsOverridesList(model, child);
	int overrides = size(overridesList);	
	int NOM = getClsNOM(model, child);
	str className = child.file; 
	str classPath = child.path;

	bool condition = false;
	real BOvR = 0.0;
	
	if (overrides <= NOM) {
		BOvR = toReal(overrides) / toReal(NOM);
	} else {
		BOvR = 1.0;
	}
	condition = BOvR < 0.33;
	debug("[overrides] <child> has more overrides than threshold", condition); 
	return condition;
} 

bool funcComplexityAbvAvg(loc cls) {
	checkIfClassHasValue(cls); // prevent key not found. 
	
	bool condition = false;
	if(useMetrics) { 
		condition = ccMap[cls].amw > getAMWAvg();
		debug("Class <cls.file> has an AMW higher than the Lanza AMW. <ccMap[cls].amw> avg: <getAMWAvg()>");
	} else {	
		// compare to AMW avg of the project. 
		condition = ccMap[cls].amw > avgAMW;
		debug("Class <cls.file> has an AMW higher than the avg. <ccMap[cls].amw> avg: <avgAMW>");
	}
	return condition;
}

bool classComplexityAbvAvg(loc cls) { 
	checkIfClassHasValue(cls);
	int clsCC = ccMap[cls].wmc;
	
	// debugging
	bool condition =  false;
	if (useMetrics) { 
		condition = clsCC > getWMCAvg();
	} else {
		condition = clsCC > avgCC;
	}
	debug("<cls> is more complex than avg: <clsCC> \> <avgCC> ");
	return condition;
}

bool classSizeAbvAvg(M3 model, loc cls) {
	int clsNOM = getClsNOM(model, cls);
	int clsLOC = 0;
	int avgLOC = 0;
	
	bool condition = false;
	if (useMetrics) {
		condition = clsNOM > getNOMAvg();
	} else {
		condition = clsLOC > avgLOC; 
	}
	return condition;
}

// Return NOM (Number of Methods).
int getClsNOM(M3 model, loc cls) {
	int NOM = 0;	
	methodContainment = {<c,m> | <c,m> <- model.containment, isMethod(m)};
	
	for (<class, method> <- methodContainment, class == cls) {
		NOM += 1;
	}
	debug("<NOM>");
	return NOM;
}

int getClsOverrides(M3 model, loc child) {
	int overrides = 0;
	str className = child.file; 
	str classPath = child.path;
	
	for (<from, to> <- model.methodOverrides, from.parent.path == classPath) { 
		overrides += 1;
	}
	return overrides;
}

rel[loc, loc] getClsOverridesList(M3 model, loc child) {
	rel[loc, loc] overrides = {};
	str className = child.file; 
	str classPath = child.path;
	
	for (<from, to> <- model.methodOverrides, from.parent.path == classPath) { 
		overrides += <from, to>;
	}
	return overrides;
}

// some anon classes can have no separate value. if they're missing add them to the map. Not sure if this causes problems by counting some classes twice.
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
	return last(paths);
}

str stripClassToName(loc location) {
	return location.file;
}