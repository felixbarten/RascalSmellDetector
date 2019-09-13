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

loc logFile = |file:///|;
loc additionalLogFile = |file:///|;
bool consoleEnabled = true;
bool logToProjectFiles = false;
bool initialized = false;
datetime startTime = now();
// Print complexity values.
public void printCyclomaticComplexity(map[loc, tuple[int wmc, real amw]] complexityVals, int total, bool printAll = false) { 
	println("[CC] Printing CC values found per class.");
	rel[loc,int] compVals = {};
	if(printAll) {
		for(key <- complexityVals) {
			tuple[int, real] comp = complexityVals[key];
			println("Cls: <key> WMC: <comp[0]> AMW: <comp[1]>");
			compVals += <comp[0], comp[1].wmc>;
		}
	}
	
	sortedList = sort(compVals, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });

	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);

	println("Top <displaySize> highest CC classes: ");
	for(int n <- [0 .. size(sortedList)]) {
		if (n > 9) break;
		println("<sortedList[n]>");
	}
	
	println("[CC] Finished printing CC values. Total CC: <total>");
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

public void startLog() {
	str fileName = printDateTime(now(), "yyyy-MM-dd_HH_mm");
	logFile = |home:///log/| + "main<fileName>.txt";
	writeFile(logFile, "Start of LogFile\n\n");
	consoleEnabled = getConsoleMode();
	logToProjectFiles = getProjectLogging();
	startTime = now();
	initialized = true;
 }

public void endLog() {
	endTime = Interval(startTime, now());
	output("<prefix> Processed project in: <endTime>");
}
// creates a logFile and returns the loc. 
public loc startProjectLog(str name, str subdir) {
	loc logLoc = |home:///log/projects/|;
	logLoc = logLoc + "<subdir>/<name>";
	writeFile(logLoc, "Start of project: <name> log");
	// override 
	additionalLogFile = logLoc;
	return logLoc; 
}
public void endProjectLog(loc log, datetime dt) {
	endTime = Interval(dt, now());
	output("Processed project in: <endTime>", log);
}

public void output (str msg) {
	if(!initialized) startLog();
	if(consoleEnabled) 
		println("<msg>");
	appendToFile(logFile, msg);
	appendToFile(logFile, "\n");
	if(logToProjectFiles && isFile(additionalLogFile)) {
		appendToFile(additionalLogFile, msg);
		appendToFile(additionalLogFile, "\n");
	}
}

public void output (str msg, loc additionalLog) {
	if(consoleEnabled) 
		println("<msg>");
	appendToFile(logFile, msg);
	appendToFile(logFile, "\n");
	appendToFile(additionalLog, msg);
	appendToFile(additionalLog, "\n");
}

public void output(str msg, str prefix) {
	str concatMsg = prefix + msg;
	if(consoleEnabled) 
		println("<concatMsg>");
	appendToFile(logFile, concatMsg); 
	appendToFile(logFile, "\n");
}