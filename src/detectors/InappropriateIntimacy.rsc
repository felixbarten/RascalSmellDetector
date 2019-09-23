module detectors::InappropriateIntimacy

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Settings;
import util::Reporting;
import util::DataStorage;

int threshold = 0;
bool debugMode = false; 
bool printAll = false;
str prefix = "[II]";

public void initialize() {
	output("<prefix> Initializing...");
	threshold = getCouplingThreshold();
	debugMode = getDebugMode();
	printAll =  getPrintIntermediaryResults();
}

// detect II with Lanza and Marinescu's metrics. 
// In the book Intensive Coupling is defined which is not the same as the Inappropriate Intimacy smell however. 
public rel[loc,loc] detectII(M3 model){	
	// 1. loop through method calls in project. 
	// 2. check if the callee is a valid file in the project otherwise discard. 
	// 3. count calls for every class. to other classes. 
	// 4. check gathered classes to see if they have more calls than the threshold.
	// 5. perform 1-4 for field access 
	
	initialize();
	map[loc, map[loc, int]] classCalls = ();
	map[loc, map[loc, int]] raw = ();
	
	map[loc, map[loc, int]] classAccess = ();
	rel[loc,loc] II = {};
	
	set[tuple[loc, loc]] suspectedII = {};
	set[tuple[loc, loc]] suspectedFAII = {};
	
	output("<prefix> Detecting II...");
	for (tuple[loc from, loc to] cu <- model.methodInvocation, isFile(cu.to)) {
		loc caller = cu.from.parent;
		loc from = cu.from;
		// convert to classes for comparison.
		// it should be a method calling a method so loc.parent shoud return the class. 
		caller.scheme = "java+class";
		loc callee = cu.to.parent;
		loc to = cu.to;
		callee.scheme = "java+class";
		
		// discard if the caller and callee are the same source. 
		if(caller == callee){
			debug("Caller is equal to callee.");
			debug("<from>, <to>");
			continue;
		}
		// <debugging>
		if(from notin raw) raw[from] = ();
		if(to notin raw[from]) raw[from][to] = 0;
		raw[from][to] += 1;
		// </debugging>
				
		if(caller notin classCalls) {
			classCalls[caller] = ();
		}
		
		if(callee notin classCalls[caller]) {
			classCalls[caller][callee] = 0;
		}
		classCalls[caller][callee] += 1;
			
		if(classCalls[caller][callee] > threshold) {
			suspectedII += <caller, callee>;
		}
	}
	// store data 
	storeIICC(classCalls);
	
	//filtering for modfiers is not possible as some fields are accessible if they have no modifier.
	// filtering out private and protected is an option though to increase performance
	for (tuple[loc from, loc to] cu <- model.fieldAccess, isFile(cu.to)) {
		loc caller = cu.from.parent;
		// make the loc valid again.
		caller.scheme = "java+class";
		loc callee = cu.to.parent;
		callee.scheme = "java+class";
		// filter out accessing own fields. 
		if (caller == callee) continue;
				
		if(caller notin classAccess) {
			classAccess[caller] = ();
		}
		
		if(callee notin classAccess[caller]) {
			classAccess[caller][callee] = 0;
		}
		classAccess[caller][callee] += 1;
		if(classAccess[caller][callee] > threshold) {
			suspectedFAII += <caller, callee>;
		}
	}
	//store data
	storeIIFA(classAccess);
	
	// if A,b is in set is B,A also available?
	for(tuple[loc a, loc b] s <- suspectedII, <s.b, s.a> in suspectedII) {
		//filter out dupes. 
		if(s notin II && <s.b, s.a> notin II) {
			II += s;
			output("<prefix> Detected II classes: <s.a.path> & <s.b.path>", printAll);
		}
	}
	output("<prefix> Finished II detection. Found <size(carrier(II))> II classes");
		
	
	printII(II);
	addIIResultsToReport(size(carrier(II)));
	
	return II;
}

// use processed data. 
void detectII(M3 model, map[loc, map[loc,int]] iicc, map[loc, map[loc,int]] iifa) {
	return;
}

public int calculateCINT() {

}

public real calculateCDISP() {


}
