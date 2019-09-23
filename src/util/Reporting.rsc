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
loc documentRoot = |home:///|;
loc projectsDir = |home:///log/projects|;
loc dataDir = |home:///data|;
loc logDir = |home:///log|;
loc reportsDir = |home:///log/reports|;
bool consoleEnabled = true;
bool logToProjectFiles = false;
bool printAll = getPrintIntermediaryResults();
bool initialized = false;
datetime startTime = now();

public void startLog(loc directory = |home:///|) {
	initializeDirectories(directory = directory);
	str fileName = printDateTime(now(), "yyyy-MM-dd__HH_mm");
	logFile = directory + "mainlog<fileName>";
	writeFile(logFile, "Start of LogFile\n\n");
	consoleEnabled = getConsoleMode();
	logToProjectFiles = getProjectLogging();
	startTime = now();
	initialized = true;
 }

// create directories
// rascaldetector
// 		data
// 			<data folders>
// 		log
// 			reports
//			projects
public void initializeDirectories(loc directory = |home:///|) {
	loc baseDirectory = directory + "rascaldetector/";
	loc logDirectory = baseDirectory + "log/";
	loc dataDirectory = baseDirectory + "data/";
	loc reportsDirectory = logDirectory + "reports/";
	loc projectsDirectory = logDirectory + "projects/";
	// set globals
	baseDir = baseDirectory;
	logDir = logDirectory;
	dataDir = dataDirectory;
	reportsDir = reportsDirectory;
	projectsDir = projectsDirectory;
	
	if(!isDirectory(baseDir)) {
		println("creating folder structure in: <resolveLocation(baseDir)>");
		mkDirectory(baseDir);
		mkDirectory(logDir);
		mkDirectory(reportsDir);
		mkDirectory(projectsDir);
		mkDirectory(dataDir);
		// cc vals 
		mkDirectory(dataDir + "CC/");
		// loc vals
		mkDirectory(dataDir + "LOC/");
		// unlikely
		mkDirectory(dataDir + "RBMOD/");
		mkDirectory(dataDir + "RBMI/");
		mkDirectory(dataDir + "RBFA/");
		mkDirectory(dataDir + "RBOV/");
		// unlikely
		mkDirectory(dataDir + "IIFA/");
		mkDirectory(dataDir + "IICC/");
		// modifiers from model. 
		mkDirectory(dataDir + "MOD/");
		// invocation from model. 
		mkDirectory(dataDir + "INV/");
		// field access 
		mkDirectory(dataDir + "FA/");
	}
}

public void startReport() {
	str fileName = printDateTime(now(), "yyyy-MM-dd__HH_mm");
	report = reportsDir + "report<fileName>";
	if(!isFile(report)) {
		writeFile(report, "Start of Report <fileName>\n\n");
	}
	// maybe write a table here but for now project summary would be fine. 
}

public void addProjectToReport(loc project, int totalLOC, int totalCC, int rbClasses) {
	appendToFile(report, "Project: <project> LOC: <totalLOC> CC: <totalCC> RB classes: <rbClasses>");
}

public void addIIResultsToReport(int countII) {
	appendToFile(report, " II: <countII>\n");
}

public void endLog() {
	endTime = Interval(startTime, now());
	output("[MAIN] Processed project in: <convertIntervalToStr(endTime)>");
}

// creates a logFile and returns the loc. 
public loc startProjectLog(str name, str subdir) {
	loc logLoc = projectsDir;
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
	output("[PROJ] Processed project in: <convertIntervalToStr(endTime)>", log);
}

// Print complexity values.
public void printCyclomaticComplexity(map[loc, tuple[int wmc, real amw]] complexityVals, int total) { 
	output("[CC] Printing CC values found per class.", printAll);
	rel[loc,int] compVals = {};
	
	for(key <- complexityVals) {
		tuple[int, real] comp = complexityVals[key];
		if(printAll) output("Cls: <key> WMC: <comp[0]> AMW: <comp[1]>");
		compVals += <key, comp[0]>;
	}
	
	sortedList = sort(compVals, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);

	output("[CC] Top <displaySize> highest CC classes: ", printAll);
	printNFromList(sortedList, 10);
	output("[CC] Total CC for project: <total>", printAll);
} 

public void printLinesOfCode(rel[loc,int] classLOC, int totalLOC, real avgLOC) {
	sortedList = sort(classLOC, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);
	
	output("[LOC] Top <displaySize> highest LOC files: ", printAll);
	printNFromList(sortedList, 10);
	output("[LOC] Total LOC in project: <totalLOC>", printAll);
}

public void printRB(rel[loc, loc,bool] rb, list[loc] notSimpleClasses) {
	if(additionalLogFile.scheme == "tmp") {
		if(!initialized) {
			startLog();
		}
		additionalLogFile = logFile;
	}
	// bad workaround for automatic separator insertion when working with locs. 
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

public void printII(rel[loc,loc] ii) {
	if(additionalLogFile.scheme == "tmp") {
		if(!initialized) {
			startLog();
		}
		additionalLogFile = logFile;
	}
	// bad workaround for automatic separator insertion when working with locs. 
	str logPthStr = additionalLogFile.scheme + ":///" + additionalLogFile.path + "__ii";
	loc logFile = toLocation(logPthStr);	
	
	writeFile(logFile, "Found <size(ii)> Classes with Inappropriate Intimacy: \n\n\n");
	for (tuple[loc l1, loc l2] r <- ii) {
		appendToFile(logFile, "<r.l1> & <r.l2>\n");
	}
	appendToFile(logFile, "All classes with II:\n\n");
	for (loc l <- carrier(ii)) {
		appendToFile(logFile, "<l>\n");
	}
	
	debug("Saved results of II detection in <resolveLocation(logFile)>");
}

void printNFromList(sortedList, int n) {
	if(n >2) n -= 1; 
	for(int n <- [0 .. size(sortedList)]) {
		if (n > 9) break;
		output("<sortedList[n]>", printAll);
	}
}

public void printLOC(tuple[int,int,int,num] locVals, bool printAll = false) {
	iprintln("<locVals>");
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

//conditional output to console to prevent clutter.
public void output(str msg, bool condition) {
	if(!initialized) startLog();
	if(consoleEnabled && condition) 
		println("<msg>");
	appendToFile(logFile, msg);
	appendToFile(logFile, "\n");
	if(logToProjectFiles && isFile(additionalLogFile)) {
		appendToFile(additionalLogFile, msg);
		appendToFile(additionalLogFile, "\n");
	}
}

public void debug(str msg) {
	if(getDebugMode()) println("[DEBUG] <msg>");
}

public void debug(str msg, bool condition){
	if(condition && getDebugMode()) println("[DEBUG] <msg>");
}

public str convertIntervalToStr(interval i) {
	Duration duration = createDuration(i);
	if (duration.days > 0) { 
		return "<duration.days> days and <duration.hours>:<duration.minutes>:<duration.seconds>";
	}
	return "<duration.hours>:<duration.minutes>:<duration.seconds>";
}

public loc getDataDirectory() {
	return dataDir;
}