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
	if (!isDirectory(directory)) {
		return [];
	}
	
	list[loc] dirs = [];
	// build list.
	for (loc dir <- directory.ls, isDirectory(dir)) {
		dirs += dir; 
	}
	return dirs;
}

//https://stackoverflow.com/questions/60512080/unregistering-m3-models
public void unregisterProject(loc project, M3 model) {
    schemesAndAuthorities 
      = {<name.scheme, name.authority> | <name, src> <- model.declarations};

    for (<scheme, authority> <- schemesAndAuthorities) {
           unregisterLocations(scheme, authority);
    }
}
