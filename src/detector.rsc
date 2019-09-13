module detector

import Prelude;
import util::FileHandling;
import util::Reporting;
import util::Settings;
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

public void main(loc directory, bool debug = false) {
	if(!isDirectory(directory)) {
		println("<directory> is not a directory!");
		return;
	}
	mainTime = now();
	setDebugMode(debug);
	setProjectLogging(true);
	
	startLog();
	str subdir = printDateTime(now(), "yyyy-MM-dd___HH_mm");
	output("<prefix> Starting detection process");
	
	output("<prefix> Gathering projects in directory: <directory>");
	list[loc] projects = gatherProjects(directory);
	output("<prefix> Gathered <size(projects)> projects.");
	for (project <- projects) {
		output("<prefix> Processing project: <project>");
		loc logFile = startProjectLog(project.file, subdir);
		startTime = now();
		
		// This method still works.
		M3 projectM3 = createM3FromDirectory(project);
		
		// report issues
		for (message <- projectM3.messages) {
			//debug("<prefix> <message>");
			break;
		}
			
		detectRB(projectM3);
		detectII(projectM3);
		
		output("<prefix> Processed project: <project>");
		endProjectLog(logFile, startTime);
	}
	
	output("<prefix> Finished processing all projects in <directory>");
	output("<prefix> Detector ran: <convertIntervalToStr(Interval(mainTime, now()))>");
	output("<prefix> End of detection process");
}

// This method can be called for a single project.
public void detectProject(loc project) {
	if (project.scheme != "project") {
		output("<prefix> Location is not a project");
		return;
	}
	N = now();
	str subdir = printDateTime(N, "yyyy-MM-dd___HH_mm");
	startLog();
	if(getProjectLogging()) {
		startProjectLog(project.authority, subdir);
	}
	output("<prefix> Starting project detection");
	M3 projectM3 = createM3FromEclipseProject(project);
		
	// report issues
	for (message <- projectM3.messages) {
		debug("<prefix> <message>");
	}
		
	RB = detectRB(projectM3);
	detectII(projectM3);
	
	if(getProjectLogging()) {
		endProjectLog(N);
	}
	endLog();
}

// temporary start method. Point to local eclipse projects. Due to the dependency on JDT from Eclipse 
// it's likely most projects for analysis will need to be imported into Eclipse.
public void s1(bool silent = false, bool debugging = false) {
	setDebugMode(debugging);
	setProjectLogging(false);
	
	detectProject(|project://JavaTestConstructs|);
	//detectProject(|project://Python-Defect-Detector|);
}

public void s2() {
	disseminateM3ModelToFile(createM3FromEclipseProject(|project://JavaTestConstructs|), printAll = true);
}