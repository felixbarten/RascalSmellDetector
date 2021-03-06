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
loc debugFile = |tmp:///|;
loc additionalLogFile = |tmp:///|;
loc documentRoot = |home:///|;
loc projectsDir = |home:///log/projects|;
loc dataDir = |home:///data|;
loc logDir = |home:///log|;
loc reportsDir = |home:///log/reports|;
bool consoleEnabled = true;
bool logToProjectFiles = false;
bool printAll = false;
bool debugMode = false;
bool logOnly = true;
bool initialized = false;
datetime startTime = now();
list[str] dataTypes = [
	"CC", 
	"LOC", 
	"NOM", 
	"M3",
	"IICC", 
	"IIFA",
	"IICOMB",
	"RBINHERITANCE"
	];

public void initializeLogger() {
	// refresh settings. 
	logToProjectFiles = getProjectLogging();
	printAll = getVerboseLoggingMode();
	debugMode = getDebuggingMode();
	logOnly = getDebuggingLogOnly();
}


public void startLog(loc directory = |home:///|) {
	initializeLogger(); 
	initializeDirectories(directory = directory);
	// printing in locale doesnt fix the 2 hours discrepancy
	datetime dt = incrementHours(now(), 2);
	str fileName = printDateTime(dt, "yyyy-MM-dd__HH_mm");
	logFile = logDir + "mainlog<fileName>";
	writeFile(logFile, "Start of LogFile\n\n");
	if(debugMode) {
		debugFile = logDir + "debug<fileName>";
		if(!isFile(debugFile)){
			 writeFile(debugFile, "Start of Debug LogFile\n\n");	
		}
	}
	consoleEnabled = getConsoleMode();
	logToProjectFiles = getProjectLogging();
	startTime = now();
	initialized = true;
 }

// create directory structure
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

	if(!isDirectory(baseDir))  {
		println("[MAIN] Creating folder structure in: <resolveLocation(baseDir)>");
	}
	createDirectory(baseDir);
	createDirectory(logDir);
	createDirectory(reportsDir);
	createDirectory(projectsDir);
	createDirectory(dataDir);
	
	for (str val <- dataTypes) {
		createDirectory(dataDir + "<val>/");
	}
}

void createDirectory(loc directory) {
	if(!isDirectory(directory)) {
		mkDirectory(directory);
	}
}

public void startReport() {
	// not sure what timezone this is. 
	datetime dt = incrementHours(now(), 2);
	str fileName = printDateTimeInLocale(dt, "yyyy-MM-dd__HH_mm_ss", "Europe/Netherlands");
	report = reportsDir + "report<fileName>";
	if(!isFile(report)) {
		writeFile(report, "Start of Report <fileName>\n\n");
		reportSettings();
	}
	// maybe write a table here but for now project summary would be fine. 
}

// log settings for data collection
public void reportSettings() {
	str disabled = "disabled";
	appendToFile(report, "[Settings]\n\n");
	appendToFile(report, "[Detector]\n");
	appendToFile(report, "Debugging: \t\t<getDebuggingMode()>\n");
	appendToFile(report, "Data storage:\t\t<getDataStorage()>\n");
	appendToFile(report, "Lanza & Marinescu avgs:\t\t<getUseMetricsAverages()>\n");
	
	
	appendToFile(report, "\n[Refused Bequest]\n");
	appendToFile(report, "Detector enabled:\t<getRBEnabled()>\n");
	appendToFile(report, "Override Threshold:\t<getBequestHighOverrideThreshold()>\n");
	appendToFile(report, "Few protected members:\t<getProtectedMemberHighThreshold()>");
	
	
	appendToFile(report, "\n\n[Inappropriate Intimacy]\n");
	appendToFile(report, "Detector enabled:\t<getIIEnabled()>\n");
	appendToFile(report, "Coupling threshold:\t<getIIEnabled() ? getCouplingThreshold() : disabled>");
	
	appendToFile(report, "\n\nEnd of Settings\n\n");
}

public void addProjectToReport(loc project, int totalLOC, int totalCC, int rbClasses) {
	appendToFile(report, "Project: <project> LOC: <totalLOC> CC: <totalCC> RB classes: <rbClasses>");
}

public void addProjectToReport(loc project, int totalLOC, int totalCC, str rbStatus) {
	appendToFile(report, "Project: <project> LOC: <totalLOC> CC: <totalCC> RB: <rbStatus>");
}


public void addIIResultsToReport(int countII) {
	appendToFile(report, " II: <countII>\n");
}

public void addRBResultsToReport(int countII) {
	appendToFile(report, " RB: <countII>\n");
}

public void addIIResultsToReport(str countII) {
	appendToFile(report, " II: <countII>\n");
}

public void addRBResultsToReport(str countII) {
	appendToFile(report, " RB: <countII>\n");
}

public void reportNewLine() {
	appendToFile(report, "\n");
}

public void endLog() {
	endTime = Interval(startTime, now());
	output("[MAIN] Processed all projects in: <convertIntervalToStr(endTime)>");
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
		output("Cls: <key> WMC: <comp[0]> AMW: <comp[1]>", printAll);
		compVals += <key, comp[0]>;
	}
	
	sortedList = sort(compVals, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);

	output("[CC] Top <displaySize> highest CC classes: ", printAll);
	printNFromList(sortedList, 10);
	output("[CC] Total CC for project: <total>", printAll);
} 

public void printCyclomaticComplexity(tuple[map[loc, tuple[int wmc, real amw]], int, int, real] complexityVals) {
	printCyclomaticComplexity(complexityVals[0], complexityVals[1], printAll = true);
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
	appendToFile(logFile, "\nAll classes with II:\n\n");
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

// move to debugging file.
public void debug(str msg) {
	if(debugMode){
		str msg = "[DEBUG] <msg>\n";
		if(!logOnly) {
			print(msg);
		}
		appendToFile(debugFile, msg);
	}
}

public void debug(str msg, bool condition){
	if(condition && debugMode) {
		if(!logOnly) {
			println("[DEBUG] <msg>");
		}
		appendToFile(debugFile, msg + "\n");
	}
	
}

public str convertIntervalToStr(interval i) {
	Duration duration = createDuration(i);
	str msg = "";
	if (duration.days > 0) { 
		msg = "<duration.days> days and ";
	} 
	msg = msg +  "<duration.hours>:<duration.minutes>:<duration.seconds>";
	if (duration.hours == 0 && duration.minutes == 0 && duration.seconds == 0) {
		msg = msg + " <duration.milliseconds> ms";
	}
	return msg; 
}

public str convertIntervalToStr(datetime dt) {
	return convertIntervalToStr(Interval(dt, now()));
}

public loc getDataDirectory() {
	return dataDir;
}

public list[str] getDataTypes() {
	return dataTypes;
}