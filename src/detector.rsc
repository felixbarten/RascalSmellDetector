module detector

import IO;
import Set;
import List;
import util::FileHandling;
import metrics::LOC;
import metrics::CC;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;


public bool debug = false;
public M3 model = createM3FromEclipseProject(|project://thesis|);

int showModel() {
	iprintln(model.extends);
	return 0;
}

public void main(loc directory) {
	if (directory.scheme != "file") {
		println("Location is not a directory");
		return;
	}
	
	println("Gathering projects");
	list[loc] projects = gatherProjects(directory);
	println("Looping through projects");
	for (p <- projects) {
		set[Declaration] projectAST = createAstsFromDirectory(p, true);
		M3 projectM3 = createM3FromDirectory(p);
		
		LOC = calculateLOC(projectM3);
		println("Processed project: <p>");
	
	}

}

public void detectProject(loc project) {

	if (project.scheme != "project") {
		println("Location is not a project");
		return;
	}
	M3 projectM3 = createM3FromEclipseProject(project);
		
	LOC = calculateLOC(projectM3);
	println("Processed project: <p>");
	
	

}


public void printModel() {
	writeFile(|project://RascalSmellDetector/model.txt|, model);
	writeFile(|project://RascalSmellDetector/containment.txt|, model.containment);
	
	return ;
}

public void startDetector() {
	loc defaultDir = |file:///path/to/dir/|;
	main(defaultDir);
}
