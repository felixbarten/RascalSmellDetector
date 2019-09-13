module util::FileHandling

import IO;
import Set;
import List;

public list[loc] gatherProjects(loc directory) {
	if (!isDirectory(directory)) 
		return [];
		
	list[loc] dirs = [];
	for (loc dir <- directory.ls, isDirectory(dir)) {
		dirs += dir; 
	}
	return dirs;
}