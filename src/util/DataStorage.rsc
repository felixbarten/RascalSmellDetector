module util::DataStorage

import Prelude;
import DateTime;
import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::m3::TypeSymbol;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;
import lang::java::jdt::m3::TypeSymbol;
import util::Settings;
import util::Reporting;
import ValueIO;

bool initialized = false; 
bool enabled = getStoreData();
loc dataDir = |tmp:///|;
str name = "default";

public void initializeDS(loc dir = |home://data|) {
	if(!enabled && initialized) return;
	println("Initializing data storage");
	initializeDirectories();
	initialized = true;
	dataDir = getDataDirectory();
}

public void initializeProject(str n) {
	name = n;
}

public bool checkProjectData(loc project) {
	// check if data files exist for this project
	name = project.file;
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
	println("<resolveLocation(dataFile)>");
	writeBinaryValueFile(dataFile, results);
}

public void storeRBFA(rel[loc,loc] results){
	debug("Storing RB data");
	loc dataFile = dataDir + "RBFA/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeRBMI(rel[loc,loc] results){
	debug("Storing RB data");
	loc dataFile = dataDir + "RBMI/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeRBMOD(rel[loc,Modifier] results){
	debug("Storing RB data");
	loc dataFile = dataDir + "RBMOD/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeRBOV(rel[loc,loc] results){
	debug("Storing RB data");
	loc dataFile = dataDir + "RBOV/<name>";
	writeBinaryValueFile(dataFile, results);
}

public void storeRBEX(rel[loc,loc] results){
	debug("Storing RB data");
	loc dataFile = dataDir + "RBEX/<name>";
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

public tuple[rel[loc,int],int,int,int,real] retrieveLOC(){
	loc dataFile = dataDir + "LOC/<name>";
	tuple[rel[loc,int],int,int,int,real] results = <{}, 0,0,0,0.0>;
	results = readBinaryValueFile(#tuple[rel[loc,int],int,int,int,real], dataFile);
	return results;
}

public tuple[map[loc, tuple[int wmc, real amw]], int, int, real] retrieveCC(){
	loc dataFile = dataDir + "CC/<name>";
	return readBinaryValueFile(#tuple[map[loc, tuple[int wmc, real amw]], int, int, real], dataFile);
}

public rel[loc,loc] retrieveRBMI(){
	loc dataFile = dataDir + "RBMI/<name>";
	return readBinaryValueFile(#rel[loc,loc], dataFile);
}

public rel[loc, Modifier] retrieveRBMOD(){
	loc dataFile = dataDir + "RBMOD/<name>";
	return readBinaryValueFile(#rel[loc,Modifier], dataFile);
}
public rel[loc, loc] retrieveRBFA(){
	loc dataFile = dataDir + "RBFA/<name>";
	return readBinaryValueFile(#rel[loc,loc], dataFile);
}

public rel[loc, loc] retrieveRBEX(){
	loc dataFile = dataDir + "RBEX/<name>";
	return readBinaryValueFile(#rel[loc,loc], dataFile);
}

public rel[loc, loc] retrieveRBOV(){
	loc dataFile = dataDir + "RBOV/<name>";
	return readBinaryValueFile(#rel[loc,loc], dataFile);
}

public map[loc, map[loc,int]] retrieveIICC(){
	loc dataFile = dataDir + "IICC/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}

public map[loc, map[loc,int]] retrieveIIFA(){
	loc dataFile = dataDir + "IIFA/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}