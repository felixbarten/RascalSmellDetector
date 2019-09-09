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

// temporary workaround. 
public M3 model = createM3FromEclipseProject(|project://Python-Defect-Detector|);

public void startProgram() {
	main();
}

public void main(loc directory, bool debug = false) {
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

public void detectProject(loc project) {
	if (project.scheme != "project") {
		println("Location is not a project");
		return;
	}
	println("Starting project detection");
	// This method still works.
	M3 projectM3 = createM3FromEclipseProject(project);
		
	detectRB(projectM3);
	detectII(projectM3);
	
	println("Processed project: <project>");
}

// temporary start method. Point to local eclipse projects. Due to the dependency on JDT from Eclipse 
// it's likely most projects for analysis will need to be imported into Eclipse.
public void s1(bool silent = false, bool debugging = false) {
	setDebugMode(debugging);
	
	detectProject(|project://JavaTestConstructs|);
	detectProject(|project://Python-Defect-Detector|);
}

public void s2() {
	disseminateM3ModelToFile(createM3FromEclipseProject(|project://JavaTestConstructs|), printAll = true);
}

public void startDetector(loc directory) {
	loc defaultDir = |file:///path/to/dir/|;
	main(defaultDir);
}


void showModel() {
	iprintln(model.extends);
}

