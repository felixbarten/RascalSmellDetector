module detector

import IO;
import Set;
import List;
import DateTime;
import util::FileHandling;
import metrics::LOC;
import metrics::CC;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;


public bool debug = false;
public M3 model = createM3FromEclipseProject(|project://Python-Defect-Detector|);

public void startProgram() {
	main();
}

public void main(loc directory) {
	if (directory.scheme != "file") {
		println("Location is not a directory");
		return;
	}
	println("Starting detection process");
	
	println("Gathering projects in directory: <directory>");
	list[loc] projects = gatherProjects(directory);
	println("Gathered projects");
	println("Looping through projects");
	for (p <- projects) {
		startTime = now();
		println("Processing project: <p>");
		set[Declaration] projectAST = createAstsFromDirectory(p, true);
		// are these enough or does my method need models generated through eclipse?
		M3 projectM3 = createM3FromDirectory(p);
		
		LOC = calculateLOC(projectM3);
		endTime = Interval(startTime, now());
		println("Processed project: <p> in <endTime>");
	
	}
	println("Finished processing all projects in <directory>");
	
	println("End of detection process");
	
}

public void detectProject(loc project = |project:///|) {
	if (project.scheme != "project") {
		println("Location is not a project");
		return;
	}
	// This method still works.
	M3 projectM3 = createM3FromEclipseProject(project);
		
	//LOC = calculateLOC(projectM3);
	//CC = calculateCCCU(projectM3);
	CC = calcClassCC(projectM3);
	printClasses(CC[0], CC[1]);
	//println("Found CC in project: <CC>");
	//showCompilationUnitModel(projectM3);
	//println("Found LOC in project: <LOC>");
	println("Processed project: <project>");
}

// refactor to somewhere else 
public void printClasses(rel[loc, int] complexityVals, int total) { 
	println("Printing CC values found per class.");
	total = 0; 
	for(tuple[loc, int] comp <- complexityVals) {
		println("<comp[0]> CC: <comp[1]>");
	}
	sortedList = sort(complexityVals, bool(tuple[loc,int] a, tuple[loc,int] b) { return a[1] > b[1]; });
	
	displaySize = size(sortedList) >= 10 ? 10 : size(sortedList);
	
	println("Top <displaySize> highest CC classes: ");
	for(int n <- [0 .. size(sortedList)]) {
		if (n > 9) break;
		println("<sortedList[n]>");
	}
	
	println("Finished printing CC values. Total CC: <total>");
} 

// temporary start method. Point to local eclipse projects. Due to the dependency on JDT from Eclipse 
// it's likely most projects for analysis will need to be imported into Eclipse.
public void s1() { 
	detectProject(|project://JavaTestConstructs|);
	detectProject(|project://Python-Defect-Detector|);
}

public void startDetector(loc defaultDir = |file:///path/to/dir/|) {
	main(defaultDir);
}


void showModel() {
	iprintln(model.extends);
}

