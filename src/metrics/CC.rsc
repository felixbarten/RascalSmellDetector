module metrics::CC

import Prelude;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Reporting;
import util::DataStorage;

str prefix = "[CC]";

// Calculates the cyclomatic complexity per compilation unit (file). 
public rel[loc, int] calculateCompUnitsCC(M3 model) {
	datetime dt = now();
	compUnitCC = {};
	output("<prefix> Calculating complexity per compilation unit");
	projectCC = 0; 
	// Do analysis per compilation unit. Less granular.
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit") {
		tempCUCC = 0;
		CUData = calculateCompUnitCC(cu);
		for(tuple[loc, int] cd <- CUData) { 
			tempCUCC += cd[1];
		}
		projectCC += tempCUCC;
		compUnitCC += <cu[0], tempCUCC>;
	}
	
	output("<prefix> Total project CC: <projectCC>");
	output("<prefix> Finishing calculating complexity in <convertIntervalToStr(dt)>");
	return compUnitCC;
	
} 

// Calculates the cyclomatic complexity per class.
// return map with WMC/AMW values per class, CC for the whole project, Average CC per class
// Average Weighted Method count for the whole project.   
public tuple[map[loc, tuple[int wmc, real amw]], int, int, real] calculateClassesCC(M3 model) {
	classCC = {};
	list[real] amwVals = [0.0];
	processedClasses = [];
	map[loc, tuple[int wmc, real amw]] CCMap = ();
	projectCC = 0; 
	output("<prefix> Calculating Cyclomatic Complexity...");
	// split files from classes. So every class is processed individually. 
	// This does have a downside that code outside of classes are not processed. But in Java this shouldn't be used!
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit" && cu[1].scheme == "java+class") {
		if (cu[1] in processedClasses) {
			debug("Already processed this class");
			continue;
		} 
		processedClasses += cu[1];
		int WMC = 0;
		real AMW = 0.0;
		loc cls = cu[1];
		classData = calculateClassCC(cu);
		for(tuple[loc, int] cd <- classData[0]) { 
			WMC += cd[1];
		}
		projectCC += WMC;
		if (toReal(classData[1]) > 0) {
		  	AMW = WMC / toReal(classData[1]);
		} else {
			AMW = toReal(WMC);
		}
		
		amwVals += AMW;
		classCC += <cu[1], WMC, AMW>;
		CCMap[cls] = <WMC, AMW>;
	}
	avgAMW = sum(amwVals) / toReal(size(amwVals));
	avgWMC = 0;
	if (size(classCC) > 0 ){
		avgWMC =(projectCC / size(classCC));
	}
	output("<prefix> Total project CC: <projectCC>");
	tuple[map[loc, tuple[int wmc, real amw]], int, int, real] results = <CCMap, projectCC, avgWMC, avgAMW>;
	
	storeCC(results);
	if (results != retrieveCC()) {
		debug("CC is not the same");
	}
	return results;
}

// Parameter in tuple [loc compilationUnit, loc class]
public tuple[rel[loc, int], int] calculateClassCC(tuple[loc, loc] unit, bool printAll = false) {
		// not entirely sure about collectBindings parameter. 
		AST = createAstFromFile(unit[1], true);
		detectedMethods = findMethods([AST]); 
		
		// This approach uses compilation units. 
		// Which is fine but if there is more than one class defined in a file this will yield bad results.		
		CC = calcMethodsCC(detectedMethods);		
		totalCC = 0;
		for (tuple[loc, int] ccval <- CC) {
			totalCC += ccval[1]; 
		}
		if (printAll) output("Total CC for Class: <unit[1]> <totalCC>");
		// include number of methods to calculate AMW in the next step.
		return <CC, size(detectedMethods)>;
}

// Updated code to new style Annotations are no longer supported in this version of rascal. 
lrel[loc, Statement] findMethods(list[Declaration] d) 
	= [<b.src, b> | /initializer(b) := d]
	+ [<b.src, b> | /method(_,_,_,_,b) := d]
	+ [<b.src, b> | /constructor(_,_,_,b) := d];


public rel[str, int] calculateMethodCC(M3 model) {
	int countConstruct = 0;
	int countInit = 0;
	int countMethod = 0;
		
	for (cu <- model.containment, cu[0].scheme == "java+method") {
		countMethod += 1;
	}
	
	output("looped through <countMethod> methods");
	
	for (cu <- model.containment, cu[0].scheme == "java+constructor") {
		countConstruct += 1;
	}
	output("looped through <countConstruct> constructors");
	
	// I found initializers referenced in the CC calculation somewhere on the internet What are they though? 
	// If you have methods and constructer surely that's everything.
	// So what counts as an initializer?
	for (cu <- model.containment, cu[0].scheme == "java+initializer") {
		countInit += 1; 
	}
	
	output("Looped through <countInit> Initializers");
	
	return {<"a", 5>, <"b", 6>};
}

rel[loc, int] calcMethodsCC(lrel[loc, Statement] methods) {
	rel[loc, int] methodCCs = {};
	
	for (tuple[loc, Statement] m <- methods) {
		methodCCs += <m[0], calcCC(m[1])>;
	}
	return methodCCs;
}

public tuple[int,real] calculateCCByLocation(loc location) {
	AST = createAstFromFile(location, true);
	detectedMethods = findMethods([AST]); 
				
	CC = calcMethodsCC(detectedMethods);		
	WMC = 0;
	for (tuple[loc, int] ccval <- CC) {
		WMC += ccval[1]; 
	}
	AMW = toReal(WMC);
	if(size(detectedMethods) > 0) {
		AMW = WMC / toReal(size(detectedMethods));
	} 
	return <WMC, AMW>;
}

// Count branching statements on the AST. https://stackoverflow.com/questions/40064886/obtaining-cyclomatic-complexity
int calcCC(Statement impl) {
    int result = 1;
    visit (impl) {
        case \if(_,_) : result += 1;
        case \if(_,_,_) : result += 1;
        case \case(_) : result += 1;
        case \do(_,_) : result += 1;
        case \while(_,_) : result += 1;
        case \for(_,_,_) : result += 1;
        case \for(_,_,_,_) : result += 1;
        case foreach(_,_,_) : result += 1;
        case \catch(_,_): result += 1;
        case \conditional(_,_,_): result += 1;
        case infix(_,"&&",_) : result += 1;
        case infix(_,"||",_) : result += 1;
    }
    return result;
}