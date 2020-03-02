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
import analysis::m3::Registry;
import util::Benchmark;

public loc defaultDir = |file:///|;
str prefix = "[MAIN]";
bool reportInitialized = false;

private void initialize(bool debugging, bool projectLogging, bool enableConsole, bool printAll, bool dataStorage, bool oneReport) {
	setDebugMode(debugging);
	setProjectLogging(projectLogging);
	setConsoleMode(enableConsole);
	setPrintIntermediaryResults(printAll);
	setStoreData(dataStorage);

	startProcessing(oneReport);
}

public void startProcessing(bool oneReport) {
	initializeDS();
	startLog();
	// don't start a new report file if 
	if(oneReport) {
		if(!reportInitialized) {
			startReport();
			reportInitialized = true;
		}
	} else {
		startReport();
	}
}

public void endProcessing() {
	endLog();
}

public void main(loc directory, bool debugging = false, bool projectLogging = true, bool console = true, bool results = false, bool dataStorage = true, bool oneReport = false) {
	if(!isDirectory(directory)) {
		println("<directory> is not a directory!");
		return;
	}
	initialize(debugging, projectLogging, console, results, dataStorage, oneReport);
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
		loc logFile = startProjectLog(project.file, subdir);
		startTime = now();
		// check datavault for processed data
		bool processed = checkProjectData(project);
		if(!checkProjectData(project)){
			processProject(project);
		} else {
			output("[PROJ] Project <project.file> has already been processed. Retrieving data...");
			reprocessProject(project);
		}
		output("<prefix> Processed project: <project>");
		endProjectLog(logFile, startTime);
		count += 1;
	}
	
	output("<prefix> Finished processing all projects in <directory>");
	output("<prefix> Detector ran: <convertIntervalToStr(Interval(mainTime, now()))>");
	output("<prefix> End of detection process");
	endProcessing();
}

void processProject(loc project) {
	N = now();
	output("<prefix> Creating M3 model...");
	M3 model = emptyM3(project);
	if(project.scheme == "project") {
		model = createM3FromEclipseProject(project);
	} else {
		model = createM3FromDirectory(project);
	}
	output("<prefix> Created M3 model in: <convertIntervalToStr(N)>");
	// report issues
	for (message <- model.messages) {
		debug("<prefix> <message>");
	}
		
	detectRB(model, project);
	detectII(model);
	cleanup(model, project);
}

void reprocessProject(loc project) {		
	LOC = retrieveLOC();
	CC = retrieveCC();
	M3 model = retrieveModel();
	// register project with rascal to rebuild location database for resolving java+class locs. 
	registerProject(project, model);

	RBINH = retrieveRBINHERITANCE();
	NOM = retrieveNOM();
	IIFA = retrieveIIFA();
	IICC = retrieveIICC();
	
	detectRB(model, project, LOC, CC, RBINH, NOM);
	detectII(model, IICC, IIFA);	
	cleanup(model, project);
}

void cleanup(M3 model, loc project) {
	// unregister file mappings so the results aren't contaminated
	// for example: project A has a dependency on project B. 
	// normally isFile(clsA) && isFile(clsB) would fail but if project B is in register it would not.
	unregisterProject(project, model);
	model = emptyM3(project);
	// force garbage collect. 
	gc();
}

// This method can be called for a single project.
public void detectProject(loc project) {
	if (project.scheme != "project") {
		output("<prefix> Location is not a project");
		return;
	}
	N = now();
	str subdir = printDateTime(N, "yyyy-MM-dd___HH_mm");
	startProcessing(false); 
	if(getProjectLogging()) {
		startProjectLog(project.authority, subdir);
	}
	output("<prefix> Starting project detection");
	
	bool processed = checkProjectData(project);
	if(!processed){
		processProject(project);
	} else {
		output("[PROJ] Project <project.file> has already been processed. Retrieving data...");
		reprocessProject(project);
	}
	if(getProjectLogging()) {
		endProjectLog(N);
	}
	endProcessing();
}

// this method will execute main() (iteration - 1)^2 number of times. VERY time consuming!
void gatherDataSet(loc directory, int min = 1, int max = 5) {
	println("Gathering dataset...");
	N = now();
	int count = 0;
	for (int i <- [min..max]) {
		for(int j <- [min..max]) {
			datetime loop = now();
			println("Running with setting: override: <i>, protected members: <j>");
			setOverrideThreshold(i);
			setProtectedMemberThreshold(j);
			setCouplingThreshold(i);
			// this may (very) slightly improve performance
			if (j == 1)
				enableIIDetector();
			if(j > 1) 
				disableIIDetector();
			
			if(count >= 1) {
				reportNewLine();
				// reprint (adjusted) settings.
				reportSettings();
			}
			main(directory, console = false, oneReport = true);
			count += 1; 
			println("Run <count> took: <convertIntervalToStr(loop)>. Total time: <convertIntervalToStr(N)>");
		}
	}
	println("Finished dataset in: <convertIntervalToStr(N)>");
}

// temporary start method. Point to local eclipse projects. Due to the dependency on JDT from Eclipse 
// it's likely most projects for analysis will need to be imported into Eclipse.
public void s1(bool console = true, bool debugging = false, bool results = false, bool storeData = true) {
	bool projectLogging = true;
	initialize(debugging, projectLogging, console, results, storeData, false);
	detectProject(|project://DetectorTests|);
	detectProject(|project://Python-Defect-Detector|);
}

public void s2() {
	disseminateM3ModelToFile(createM3FromEclipseProject(|project://DetectorTests|), printAll = true);
}

public void s3() {
	gatherDataSet(|home:///projects/Systems3|);
}

public void s4() {
	main(|home:///projects/Systems3|);
}

public void s5() {
	//main(|file:///I:/corpus/pt1/20130901r/Systems|);
	main(|file:///I:/corpus/pt2/20130901r/Systems|);
}

public void s6() {
	//main(|file:///I:/corpus/pt1/20130901r/Systems|);
	gatherDataSet(|file:///I:/corpus/pt1/20130901r/Systems|, min = 1, max = 8);
}

public void test1() {
	println("Starting test");
	enableDebugging();
	enableLanzaMarinescuAvg();
	main(|home:///projects|);
}
public void s7(loc directory) {
	N = now();
	//forgot a few permutations when running my data set. 
	setOverrideThreshold(3);
	setProtectedMemberThreshold(4);
	setCouplingThreshold(3);
	main(directory, console = false, oneReport = true);
	
	setOverrideThreshold(4);
	setProtectedMemberThreshold(3);
	setCouplingThreshold(4);
	main(directory, console = false, oneReport = true);
	println("Finished dataset in: <convertIntervalToStr(N)>");

}