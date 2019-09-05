module metrics::CC

import IO;
import Set;
import List;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

// Calculates the cyclomatic complexity per compilation unit (file). 
public rel[loc, int] calcCompUnitCC(M3 model) {
	compUnitCC = {};
	println("Calculating complexity per compilation unit");
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
	
	println("Total project CC: <projectCC>");
	println("finishing calculating complexity");
	return compUnitCC;
	
}

// Calculates the cyclomatic complexity per class. 
public tuple[rel[loc, int], int] calcClassCC(M3 model) {
	classCC = {};
	processedClasses = [];
	projectCC = 0; 
	println("Calculating complexity per Java Class");
	// split files from classes. So every class is processed individually. 
	//This does have a downside that code outside of classes are not processed. But in Java this shouldn't be used!
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit" && cu[1].scheme == "java+class") {
		if (cu[1] in processedClasses) {
			break;
		} 
		processedClasses += cu[1];
		tempClassCC = 0;
		classData = calculateClassCC(cu);
		for(tuple[loc, int] cd <- classData) { 
			tempClassCC += cd[1];
		}
		projectCC += tempClassCC;
		classCC += <cu[1], tempClassCC>;
	}
	
	println("Finished calculating complexity");
	println("Total project CC: <projectCC>");
	return <classCC, projectCC>;	
}

// Parameter in tuple [loc compilationUnit, loc class]
public rel[loc, int] calculateClassCC(tuple[loc, loc] unit) {
		// compilationunit is index 0. class is index 1 
		AST = createAstFromFile(unit[1], true);
		detectedMethods = findMethods([AST]); 
		
		// This approach uses compilation units. Which is fine but if there is more than one class defined in a file this will yield bad results.
		//println("<detectedMethods>");
		println("Found <size(detectedMethods)> methods in compilationUnit <unit[1]>");
		
		//println("Submethod: <m> of class <model>");
		
		
		CC = calcMethodsCC(detectedMethods);
		//println("<CC>");
		
		totalCC = 0;
		for (tuple[loc, int] ccval <- CC) {
			totalCC += ccval[1]; 
		}
		println("Total CC for Class <totalCC>");

		return CC;
}

// Update code to new style Annotations are no longer supported in this version of rascal. 
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
	
	println("looped through <countMethod> methods");
	
	for (cu <- model.containment, cu[0].scheme == "java+constructor") {
		countConstruct += 1;
	}
	println("looped through <countConstruct> constructors");
	
	// I found initializers referenced in the CC calculation somewhere on the internet What are they though? 
	// If you have methods and constructer surely that's everything.
	// So what counts as an initializer?
	for (cu <- model.containment, cu[0].scheme == "java+initializer") {
		countInit += 1; 
	}
	
	println("Looped through <countInit> Initializers");
	
	return {<"a", 5>, <"b", 6>};
}

rel[loc, int] calcMethodsCC(lrel[loc, Statement] methods) {
	rel[loc, int] methodCCs = {};
	
	for (tuple[loc, Statement] idk <- methods) {
		methodCCs += <idk[0], calcCC(idk[1])>;
			
	}
	return methodCCs;
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

public void showCompilationUnitModel(M3 model) {
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit") {
			println();
			println("<cu>");
			println();
		}
}