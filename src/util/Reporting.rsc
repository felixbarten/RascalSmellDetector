module util::Reporting

import Prelude;
import DateTime;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeSymbol;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::TypeSymbol;
import analysis::m3::TypeSymbol;
import util::Settings;

loc report = |tmp:///|;
loc logFile = |tmp:///|;
loc additionalLogFile = |tmp:///|;
bool consoleEnabled = true;
bool logToProjectFiles = false;
bool initialized = false;
datetime startTime = now();
// Print complexity values.
public void printCyclomaticComplexity(map[loc, tuple[int wmc, real amw]] complexityVals, int total, bool printAll = false) { 
	output("[CC] Printing CC values found per class.");
	rel[loc,int] compVals = {};
	
	for(key <- complexityVals) {
		tuple[int, real] comp = complexityVals[key];
		if(printAll) output("Cls: <key> WMC: <comp[0]> AMW: <comp[1]>");
		compVals += <key, comp[0]>;
	}
	
	sortedList = sort(compVals, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);

	output("Top <displaySize> highest CC classes: ");
	for(int n <- [0 .. size(sortedList)]) {
		if (n > 9) break;
		output("<sortedList[n]>");
	}
	output("[CC] Total CC for project: <total>");
} 

public void printLinesOfCode(rel[loc,int] classLOC, int totalLOC, real avgLOC) {
	sortedList = sort(classLOC, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);
	
	output("Top <displaySize> highest LOC files: ");
	for(int n <- [0 .. size(sortedList)]) {
		if (n > 9) break;
		output("<sortedList[n]>");
	}
	output("[LOC] Total LOC in project: <totalLOC>");
}

public void printRB(rel[loc, loc,bool] rb, list[loc] notSimpleClasses) {
	if(additionalLogFile.scheme == "tmp") {
		if(!initialized) {
			// not initialized
			startLog();
		}
		additionalLogFile = logFile;
	}
	// bad workaround for automatic separators when working with locs. 
	str logPthStr = additionalLogFile.scheme + ":///" + additionalLogFile.path + "__rb";
	
	loc logFile = toLocation(logPthStr);	
	
	writeFile(logFile, "Found <size(rb)> Classes with Refused Bequest: \n\n\n");
	for (tuple[loc child, loc parent, bool detected] r <- rb) {
		appendToFile(logFile, r.child.path);
		appendToFile(logFile, "\n");
	}
	debug("Saved results of RB detection in <resolveLocation(logFile)>");
	
	logPthStr = additionalLogFile.scheme + ":///" + additionalLogFile.path + "__nontrivial";
	loc logFile2 = toLocation(logPthStr);
	writeFile(logFile2, "Found <size(notSimpleClasses)> non-trivial classes: \n\n\n");
	for (loc l <- notSimpleClasses) {
		appendToFile(logFile2, l.path);
		appendToFile(logFile2, "\n");
	}
}

public void printLOC(tuple[int,int,int,num] locVals, bool printAll = false) {
	iprintln("<locVals>");
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
	str fileName = printDateTime(now(), "yyyy-MM-dd__HH_mm");
	logFile = |home:///log/| + "mainlog<fileName>";
	writeFile(logFile, "Start of LogFile\n\n");
	consoleEnabled = getConsoleMode();
	logToProjectFiles = getProjectLogging();
	startTime = now();
	initialized = true;
 }

public void startReport() {
	str fileName = printDateTime(now(), "yyyy-MM-dd__HH_mm");
	report = |home:///log/reports| + "report<fileName>";
	if(!isFile(report)) {
		writeFile(report, "Start of Report <fileName>\n\n");
	}
	// maybe write a table here but for now project summary would be fine. 
}

public void addProjectToReport(loc project, int totalLOC, int totalCC, int rbClasses) {
	appendToFile(report, "Project: <project> LOC: <totalLOC> CC: <totalCC> RB classes: <rbClasses>");
}

public void addIIResultsToReport() {
	appendToFile(report, "\n");
}

public void endLog() {
	endTime = Interval(startTime, now());
	output("<prefix> Processed project in: <convertIntervalToStr(endTime)>");
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

public void endProjectLog(datetime dt) {
	endTime = Interval(dt, now());
	output("[PROJ] Processed project in: <convertIntervalToStr(endTime)>", additionalLogFile);
}


public void endProjectLog(loc log, datetime dt) {
	endTime = Interval(dt, now());
	output("Processed project in: <convertIntervalToStr(endTime)>", log);
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

public str convertIntervalToStr(interval i) {
	Duration duration = createDuration(i);
	return "<duration.hours>:<duration.minutes>:<duration.seconds>";
}