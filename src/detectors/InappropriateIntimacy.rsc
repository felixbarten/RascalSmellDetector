module detectors::InappropriateIntimacy

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Settings;
import util::Reporting;

int threshold = 0;
bool debugMode = false; 

public void initialize() {
	threshold = getCouplingThreshold();
	debugMode = getDebugMode();
}

// detect II with Lanza and Marinescu's metrics. 
// In the book Intensive Coupling is defined which is not the same as the Inappropriate Intimacy smell however. 
public bool detectII(M3 model){	
	// 1. loop through method calls in project. 
	// 2. check if the callee is a valid file in the project otherwise discard. 
	// 3. count calls for every class. to other classes. 
	// 4. check gathered classes to see if they have more calls than the threshold.
	// 5. perform 1-4 for field access 
	
	initialize();
	map[loc, map[loc, int]] classCalls = ();
	map[loc, map[loc, int]] classAccess = ();
	
	set[tuple[loc, loc]] suspectedII = {};
	set[tuple[loc, loc]] suspectedFAII = {};
	
	for (tuple[loc from, loc to] cu <- model.methodInvocation, isFile(cu.to)) {
		loc caller = cu.from.parent;
		// make the loc valid again.
		caller.scheme = "java+class";
		loc callee = cu.to.parent;
		callee.scheme = "java+class";
		
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
	
	
	//filtering for modfiers is not possible as some fields are accessible if they have no modifier.
	// filtering out private and protected is an option though to increase performance
	for (tuple[loc from, loc to] cu <- model.fieldAccess, isFile(cu.to)) {
		loc caller = cu.from.parent;
		// make the loc valid again.
		caller.scheme = "java+class";
		loc callee = cu.to.parent;
		callee.scheme = "java+class";
				
		if(caller notin classAccess) {
			classAccess[caller] = ();
		}
		
		if(callee notin classAccess[caller]) {
			classAccess[caller][callee] = 0;
		}
		classAccess[caller][callee] += 1;
		if(classAccess[caller][callee] > threshold && caller != callee) {
			suspectedFAII += <caller, callee>;
		}
	}
	
	
	//iprint("<suspectedII>");
	if(getDebugMode()) {
		debug("Printing suspect classes from II detection", true);
		for(val <- suspectedII) {
			debug("Caller: <val[0]>, callee: <val[1]>");
		}
		for(val <- suspectedFAII) {
			debug("Access: <val[0]>, access from: <val[1]>");
		}
	}
	
	
	bool condition = false;
	
	
	addIIResultsToReport();
	
	return condition;
}

public int calculateCINT() {

}

public real calculateCDISP() {


}
