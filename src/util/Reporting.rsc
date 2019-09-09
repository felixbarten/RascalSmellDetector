module util::Reporting

import Prelude;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeSymbol;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::TypeSymbol;
import analysis::m3::TypeSymbol;
import util::Settings;

// Print complexity values.
public void printCyclomaticComplexity(map[loc, tuple[int wmc, real amw]] complexityVals, int total, bool printAll = false) { 
	println("Printing CC values found per class.");
	if(printAll) {
		for(key <- complexityVals) {
			tuple[int, real] comp = complexityVals[key];
			println("Cls: <key> WMC: <comp[0]> AMW: <comp[1]>");
		}
	}
	
	println("Finished printing CC values. Total CC: <total>");
} 

public void printLOC(tuple[int,int,int,num] locVals, bool printAll = false) {
	iprintln("<locVals>");
}


public void disseminateM3ModelToFile(M3 m, loc fileLoc = |home:///log/modellog.txt|, bool printAll = false) { 
	println("Printing entire M3 model to file");
	println("Your log file is found here: <resolveLocation(fileLoc)>");
	
	usesFile = |home:///log/uses.txt|;
	declFile = |home:///log/decl.txt|;
	typeFile = |home:///log/type.txt|;
	nameFile = |home:///log/names.txt|;
	modelFile = |home:///log/model.txt|;
	
	writeFile(fileLoc, "Start of model\n\n");
	writeFile(declFile, "Start of Declarations\n\n");
	appendToFile(fileLoc, "declarations:\n\n");
	
	for (tuple[loc,loc] d <- m.declarations) {
		appendToFile(fileLoc, "<d>\n");
		appendToFile(declFile, "<d>\n");
	}
		
	appendToFile(fileLoc, "\n Finished model");
	
	println("Finished printing M3 model.");

	writeFile(typeFile, "Start of Types\n\n");
	appendToFile(fileLoc, "\n");
	for (tuple[loc, TypeSymbol] d <- m.types) {
		appendToFile(fileLoc, "<d>\n");
		appendToFile(typeFile, "<d>\n");
	}
	
	writeFile(usesFile, "Start of Uses\n\n");
	appendToFile(fileLoc, "\n");
	for (tuple[loc,loc] d <- m.uses) {
		appendToFile(fileLoc, "<d>\n");
		appendToFile(usesFile, "<d>\n");
	}
	
	writeFile(nameFile, "Start of Names\n\n");
	appendToFile(fileLoc, "\n");
	for (tuple[str,loc] d <- m.names) {
		appendToFile(fileLoc, "<d>\n");
		appendToFile(nameFile, "<d>\n");
	
	}
	
	if(printAll) {
		writeFile(modelFile, m);
	}
}

public void showCompilationUnitModel(M3 model) {
	for (cu <- model.containment, cu[0].scheme == "java+compilationUnit") {
			println();
			println("<cu>");
			println();
		}
}

public void debug(str msg) {
	if(getDebugMode()) println("[DEBUG] <msg>");
}

public void debug(str msg, bool condition){
	if(condition && getDebugMode()) println("[DEBUG] <msg>");
}