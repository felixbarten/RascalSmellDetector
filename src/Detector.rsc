module Detector

import Prelude;
import util::FileHandling;
import util::Reporting;
import util::Settings;
import util::DataStorage;
import metrics::LOC;
import metrics::CC;
import detectors::RefusedBequest;
import detectors::InappropriateIntimacy;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

public loc defaultDir = |file:///|;
str prefix = "[MAIN]";

private void initialize(bool debugging, bool projectLogging, bool enableConsole, bool printAll, bool dataStorage) {
	setDebugMode(debugging);
	setProjectLogging(projectLogging);
	setConsoleMode(enableConsole);
	setPrintIntermediaryResults(printAll);
	setStoreData(dataStorage);

	startProcessing();
}

public void main(loc directory, bool debugging = false, bool projectLogging = true, bool console = true, bool results = false, bool dataStorage = true) {
	if(!isDirectory(directory)) {
		println("<directory> is not a directory!");
		return;
	}
	initialize(debugging, projectLogging, console, results, dataStorage);
	mainTime = now();

	str subdir = printDateTime(now(), "yyyy-MM-dd___HH_mm");
	output("<prefix> Starting detection process");
	
	output("<prefix> Gathering projects in directory: <directory>");
	list[loc] projects = gatherProjects(directory);
	output("<prefix> Gathered <size(projects)> projects.");
	int count = 1; 
	int projectNum = size(projects);
	for (project <- projects) {
		output("<prefix> Processing project <count> of <projectNum>: <project>");
		initializeProject(project.file);
		loc logFile = startProjectLog(project.file, subdir);
		startTime = now();
		M3 projectM3 = createM3FromDirectory(project);
		
		// report issues
		for (message <- projectM3.messages) {
			debug("<prefix> <message>");
		}
			
		detectRB(projectM3, project);
		detectII(projectM3);
		
		output("<prefix> Processed project: <project>");
		endProjectLog(logFile, startTime);
		count += 1;
	}
	
	output("<prefix> Finished processing all projects in <directory>");
	output("<prefix> Detector ran: <convertIntervalToStr(Interval(mainTime, now()))>");
	output("<prefix> End of detection process");
	endProcessing();
}

// This method can be called for a single project.
public void detectProject(loc project) {
	if (project.scheme != "project") {
		output("<prefix> Location is not a project");
		return;
	}
	N = now();
	str subdir = printDateTime(N, "yyyy-MM-dd___HH_mm");
	startProcessing(); 
	if(getProjectLogging()) {
		startProjectLog(project.authority, subdir);
	}
	output("<prefix> Starting project detection");
	M3 projectM3 = createM3FromEclipseProject(project);
		
	// report issues
	for (message <- projectM3.messages) {
		debug("<prefix> <message>");
	}
		
	if(getProjectLogging()) {
		endProjectLog(N);
	}
	
	detectRB(projectM3, project);
	detectII(projectM3);
	
	endProcessing();
}

// start is a keyword??
public void startProcessing() {
	initializeDS();
	startLog();
	startReport();
}

public void endProcessing() {
	endLog();
}

// temporary start method. Point to local eclipse projects. Due to the dependency on JDT from Eclipse 
// it's likely most projects for analysis will need to be imported into Eclipse.
public void s1(bool console = true, bool debugging = false, bool results = true) {
	initialize(debugging, true, console, results);
	detectProject(|project://DetectorTests|);
	detectProject(|project://Python-Defect-Detector|);
}

public void s2() {
	disseminateM3ModelToFile(createM3FromEclipseProject(|project://DetectorTests|), printAll = true);
}