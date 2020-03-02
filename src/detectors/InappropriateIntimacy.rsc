module detectors::InappropriateIntimacy

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Settings;
import util::Reporting;
import util::DataStorage;

int  threshold = 0;
bool debugMode = false; 
bool printAll = false;
str  prefix = "[II]";

public void initialize() {
	threshold = getCouplingThreshold();
	debugMode = getDebugMode();
	printAll =  getPrintIntermediaryResults();
}

// detect II with Fowler's smell definition.
public rel[loc,loc] detectII(M3 model){	
	// 1. loop through method calls in project. 
	// 2. check if the callee is a valid(accessible) file in the project otherwise discard. 
	// 3. count calls for every class. to other classes. 
	// 4. perform 1-3 for field access 
	// 5. combine maps.
	// 6. check if any matches have more coupling than the threshold. 
	if(!getIIEnabled()) {
		addIIResultsToReport("disabled");
		return {};
	}
	datetime N = now();
	initialize();
	map[loc, map[loc, int]] classCalls = (); // methods
	map[loc, map[loc, int]] classAccess = (); // fields
	map[loc, map[loc, int]] rawCC = (); // all mappings from A to B
	map[loc, map[loc, int]] rawFA = ();

	rel[loc,loc] II = {};
	
	output("<prefix> Detecting II...");
	int count = 0;
	// loop through method invocations where the location is a valid file within the project.
	for (tuple[loc from, loc to] cu <- model.methodInvocation, isFile(cu.to)) {
		loc caller = cu.from.parent;
		loc callee = cu.to.parent;
		// copy vars so they can be stored in their original form.
		loc from = cu.from;
		loc to = cu.to;
		
		// convert schemes to classes for comparison.
		caller.scheme = "java+class";
		callee.scheme = "java+class";
		
		// discard if the caller and callee are the same source.
		if(caller == callee){
			continue;
		}
		// <debugging>
		rawCC = addIfAbsent(from, to, rawCC);
		rawCC[from][to] += 1;
		// </debugging>
		
		
		classCalls = addIfAbsent(caller, callee, classCalls);
		// increment callcounter
		classCalls[caller][callee] += 1;

		count += 1;
		if(count % 10000 == 0) {
			output("[II] Processed <count> method invocations");
		}
	}
	// store method call data 
	storeIICC(classCalls);
	
	//filtering for modfiers is not possible as some fields are accessible if they have no modifier.
	int fieldCount = 0;
	for (tuple[loc from, loc to] cu <- model.fieldAccess, isFile(cu.to)) {
		loc caller = cu.from.parent;
		loc callee = cu.to.parent;	
		loc from = cu.from;
		loc to = cu.to;	
		// make the loc valid again.
		caller.scheme = "java+class";
		callee.scheme = "java+class";
		// filter out accessing own fields. 
		if (caller == callee) {
			continue;
		}
		// <debugging>
		rawFA = addIfAbsent(from, to, rawFA);
		rawFA[from][to] += 1;
		// </debugging>
				
		classAccess = addIfAbsent(caller, callee, classAccess);
		classAccess[caller][callee] += 1;
		
		fieldCount += 1;
		if(fieldCount % 10000 == 0) {
			output("[II] Processed <fieldCount> accessed fields.");
		}
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

// Add keys to map if they don't exist.
map[loc, map[loc, int]] addIfAbsent(loc caller, loc callee, map[loc, map[loc, int]] mapData) {
	if(caller notin mapData) {
		mapData[caller] = ();
	}
	if(callee notin mapData[caller]) {
		mapData[caller][callee] = 0;
	}
	return mapData;
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
				output("Amended record: <record> -\> <updatedValue>", printAll);
			}
		}
	}	

	for (caller <- matches) {
		for(callee <- matches[caller]) {
			// add suspect when above threshold. 
			if(matches[caller][callee] > threshold) {
				IISuspects += <caller, callee>;
			}	
		}
	}
	if(storeData) {
		storeIICOMB(matches);
	}
	
	output("<prefix> Size before <origSize> size after: <size(matches)>");
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
