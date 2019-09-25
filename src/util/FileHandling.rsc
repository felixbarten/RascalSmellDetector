module util::FileHandling

import IO;
import Set;
import List;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

// returns list of directories in root directory.
public list[loc] gatherProjects(loc directory) {
	if (!isDirectory(directory)) 
		return [];
		
	list[loc] dirs = [];
	for (loc dir <- directory.ls, isDirectory(dir)) {
		dirs += dir; 
	}
	return dirs;
}

// reverse engineering from the analysis::m3::Registry.rsc library 
public void unregisterProject(loc project, M3 model) {
	rel[str scheme, loc name, loc src] perScheme 
      = {<name.scheme, name, src> | <name, src> <- model.declarations};
      
	for (str scheme <- perScheme<scheme>) {
	       unregisterLocations(scheme, project.authority);
	}

}