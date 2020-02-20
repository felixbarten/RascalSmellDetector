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
	threshold = getCouplingThreshold();
	debugMode = getDebugMode();
	printAll =  getPrintIntermediaryResults();
}

// detect II with Lanza and Marinescu's metrics. 
// In the book Intensive Coupling is defined which is not the same as the Inappropriate Intimacy smell however. 
public rel[loc,loc] detectII(M3 model){	
	// 1. loop through method calls in project. 
	// 2. check if the callee is a valid(accessible) file in the project otherwise discard. 
	// 3. count calls for every class. to other classes. 
	// 4. check gathered classes to see if they have more calls than the threshold.
	// 5. perform 1-4 for field access 
	if(!getIIEnabled()) {
		addIIResultsToReport("disabled");
		return {};
	}
	datetime N = now();
	
	initialize();
	// method calls
	map[loc, map[loc, int]] classCalls = ();
	map[loc, map[loc, int]] rawCC = ();
	map[loc, map[loc, int]] rawFA = ();
	
	// field access
	map[loc, map[loc, int]] classAccess = ();
	rel[loc,loc] II = {};
	
	output("<prefix> Detecting II...");
	int count = 0;
	// loop through method invocations where the location is a valid file within the project.
	for (tuple[loc from, loc to] cu <- model.methodInvocation, isFile(cu.to)) {
		loc caller = cu.from.parent;
		loc from = cu.from;
		// convert to classes for comparison.
		// it should be a method calling a method so loc.parent should return the class. 
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
		if(from notin rawCC) {
			rawCC[from] = ();
		}
		if(to notin rawCC[from]) {
			rawCC[from][to] = 0;
		}
		rawCC[from][to] += 1;
		// </debugging>
		
		// add if not present. 
		if(caller notin classCalls) {
			classCalls[caller] = ();
		}
		
		// add to submap if not present. 
		if(callee notin classCalls[caller]) {
			classCalls[caller][callee] = 0;
		}
		// increment callcounter
		classCalls[caller][callee] += 1;
			/*
		if(classCalls[caller][callee] > threshold) {
			suspectedII += <caller, callee>;
		}*/
		count += 1;
		if(count % 10000 == 0) {
			output("[II] Processed <count> method invocations");
		}
	}
	// store method call data 
	storeIICC(classCalls);
	
	//filtering for modfiers is not possible as some fields are accessible if they have no modifier.
	// filtering out private and protected is an option though to increase performance
	int fieldCount = 0;
	for (tuple[loc from, loc to] cu <- model.fieldAccess, isFile(cu.to)) {
		loc from = cu.from;
		loc to = cu.to;	
		loc caller = cu.from.parent;
		// make the loc valid again.
		caller.scheme = "java+class";
		loc callee = cu.to.parent;
		callee.scheme = "java+class";
		// filter out accessing own fields. 
		if (caller == callee) continue;
				
		// <debugging>
		if(cu.from notin rawFA) {
			rawFA[cu.from] = ();
		}
		if(to notin rawFA[from]) {
			rawFA[cu.from][cu.to] = 0;
		}
		rawFA[from][to] += 1;
		// </debugging>
				
		if(caller notin classAccess) {
			classAccess[caller] = ();
		}
		
		if(callee notin classAccess[caller]) {
			classAccess[caller][callee] = 0;
		}
		classAccess[caller][callee] += 1;
		fieldCount += 1;
		if(fieldCount % 10000 == 0) {
			output("[II] Processed <fieldCount> accessed fields.");
		}
		/*
		if(classAccess[caller][callee] > threshold) {
			suspectedFAII += <caller, callee>;
		}*/
	}
	//store field access data
	storeIIFA(classAccess);
	storeRawDebugMaps(rawCC, rawFA);
	
	rel[loc,loc] suspectedII = combineThresholdMaps(classCalls, classAccess, true);
	
	II = checkSuspects(suspectedII);
	output("<prefix> Found <size(carrier(II))> II classes.");
	output("<prefix> Finished II detection in <convertIntervalToStr(N)>.");
	printII(II);
	addIIResultsToReport(size(carrier(II)));
	
	return II;
}

rel[loc,loc] checkSuspects(set[tuple[loc,loc]] suspects) {
	rel[loc,loc] II = {};
	// if A,B is in set is B,A also available?
	for(tuple[loc a, loc b] s <- suspects, <s.b, s.a> in suspects) {
		//filter out dupes. 
		if(s notin II && <s.b, s.a> notin II) {
			II += s;
			output("<prefix> Detected II classes: <s.a.path> & <s.b.path>", printAll);
		}
	}
	return II;
}

// combines the threshold maps and returns a suspected II relation. 
rel[loc,loc] combineThresholdMaps(map[loc, map[loc, int]] iicc, map[loc, map[loc, int]] iifa, bool storeData) {
	datetime N = now();
	int origSize = size(iicc);
	map[loc, map[loc, int]] matches = iicc;
	rel[loc, loc] IISuspects = {};
	// loop through fa map
	for (caller <- iifa) {
		// prevent nullpointer
		if(caller notin matches) {
			matches[caller] = ();
		}
	
		for (callee <- iifa[caller]){
			if (callee notin matches[caller]) {
				matches[caller][callee] = iifa[caller][callee];
			} else {
				// merge records.
				int record = matches[caller][callee];
				int updatedValue = record + iifa[caller][callee];
				matches[caller][callee] =  updatedValue;
				output("Amended record: <record> -\> <updatedValue>");
			}
		}
	}	

	for (caller <- matches) {
		for(callee <- matches[caller]) {
			// add match if above threshold
			if(matches[caller][callee] > threshold) {
				IISuspects += <caller, callee>;
			}	
		}
	}
	if(storeData) {
		storeIICOMB(matches);
	}
	
	output("Size before <origSize> size after: <size(matches)>");
	output("<prefix> Finished merging maps in <convertIntervalToStr(N)>.");
	return IISuspects;
}

// use processed data. 
public rel[loc,loc] detectII(M3 model, map[loc, map[loc,int]] iicc, map[loc, map[loc,int]] iifa) {
	N = now();
	initialize();
	output("<prefix> II detector state restored.");
	rel[loc,loc] II = {};
	set[tuple[loc, loc]] suspectedII = {};
	set[tuple[loc, loc]] suspectedFAII = {};
	
	rel[loc,loc] suspects = combineThresholdMaps(iicc, iifa, false);
	
	II = checkSuspects(suspects);
	output("<prefix> Found <size(carrier(II))> II classes");
	output("<prefix> Finished II detection in <convertIntervalToStr(N)>.");
	printII(II);
	addIIResultsToReport(size(carrier(II)));
	return II;
}

public int calculateCINT() {

}

public real calculateCDISP() {


}
