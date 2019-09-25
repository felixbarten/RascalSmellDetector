module util::DataStorage

import Prelude;
import DateTime;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeSymbol;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import util::Settings;
import util::Reporting;
import ValueIO;

bool initialized = false; 
bool enabled = getStoreData();
loc dataDir = |tmp:///|;
str name = "default";

public void initializeDS(loc dir = |home://data|) {
	if(!enabled && initialized) return;
	initializeDirectories();
	initialized = true;
	dataDir = getDataDirectory();
}

public bool checkProjectData(loc project) {
	// check if data files exist for this project
	name = project.file;
	if(project.scheme == "project")
		name = project.authority;
		
	list[bool] projectData = [];
	for (str dataType <- getDataTypes()) {
		projectData += checkData(dataType);
	}
	if (true in projectData && false in projectData) output("Project data incomplete... processing again.");
	return false notin projectData;
}

bool checkData(str folder) {
	loc dataFile = dataDir + "<folder>/<name>";
	if(isFile(dataFile) && getFileLength(dataFile) > 0) return true;
	return false;
}

public void storeCC(tuple[map[loc, tuple[int wmc, real amw]], int, int, real] results){
	debug("Storing CC data");
	if(!enabled) return;
	loc dataFile = dataDir + "CC/" + "<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeLOC(tuple[rel[loc,int],int,int,int,real] results){
	debug("Storing LOC data");
	if(!enabled) return;
	loc dataFile = dataDir + "LOC/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeIICC(map[loc, map[loc, int]] results){
	debug("Storing II ClassCalls data");
	loc dataFile = dataDir + "IICC/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeIIFA(map[loc, map[loc, int]] results){
	debug("Storing II FA data");
	loc dataFile = dataDir + "IIFA/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeModel(M3 model) {
	loc dataFile = dataDir + "M3/<name>";
	writeBinaryValueFile(dataFile, model);
}

public tuple[rel[loc,int],int,int,int,real] retrieveLOC(){
	loc dataFile = dataDir + "LOC/<name>";
	tuple[rel[loc,int],int,int,int,real] results = <{}, 0,0,0,0.0>;
	results = readBinaryValueFile(#tuple[rel[loc,int],int,int,int,real], dataFile);
	return results;
}

public tuple[map[loc, tuple[int wmc, real amw]], int, int, real] retrieveCC(){
	loc dataFile = dataDir + "CC/<name>";
	tuple[map[loc, tuple[int wmc, real amw]], int, int, real] results = readBinaryValueFile(#tuple[map[loc, tuple[int wmc, real amw]], int, int, real], dataFile);
	return results;
}

public map[loc, map[loc,int]] retrieveIICC(){
	loc dataFile = dataDir + "IICC/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}

public map[loc, map[loc,int]] retrieveIIFA(){
	loc dataFile = dataDir + "IIFA/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}

public M3 retrieveModel() {
	loc dataFile = dataDir + "M3/<name>";
	return readBinaryValueFile(#M3, dataFile);
}