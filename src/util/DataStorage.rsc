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
	if(project.scheme == "project") {
		name = project.authority;
	}
		
	list[bool] projectData = [];
	for (str dataType <- getDataTypes()) {
		projectData += checkData(dataType);
	}
	if (true in projectData && false in projectData) {
		output("Project data incomplete! Processing again...");
	}
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

public void storeIICOMB(map[loc, map[loc, int]] results){
	debug("Storing II COMB data");
	loc dataFile = dataDir + "IICOMB/<name>";
	loc dataFile2 = dataDir + "IICOMB/<name>_debug";
	mapToFile(dataFile2, results);
	writeBinaryValueFile(dataFile, results);
}

public void storeRBDetectorInformation(map[loc, int] usedInheritanceMembers, map[loc, rel[loc,loc]] rawData) {
	debug("Storing RB Detection data");
	loc dataFile = dataDir + "RBINHERITANCE/<name>";
	loc dataFile2 = dataDir + "RBINHERITANCE/<name>_debug";
	writeBinaryValueFile(dataFile, usedInheritanceMembers);
	mapToFile(dataFile2, rawData);
}

public void storeNOM(map[loc, int] NOM) {
	debug("Storing NOM data");
	loc dataFile = dataDir + "NOM/<name>";
	writeBinaryValueFile(dataFile, NOM);
}

// store unstripped locations for later reference. 
public void storeRawDebugMaps(map[loc, map[loc, int]] rawCC, map[loc, map[loc, int]] rawFA){
	debug("Storing Raw Debugging maps.");
	loc dataFileCC = dataDir + "RAWCC/<name>";
	loc dataFileFA = dataDir + "RAWFA/<name>";
	
	loc dataFileCC2 = dataDir + "RAWCC/<name>_manual";
	loc dataFileFA2 = dataDir + "RAWFA/<name>_manual";
	
	
	mapToFile(dataFileCC2, rawCC);
	mapToFile(dataFileFA2, rawFA);
	
	
	writeTextValueFile(dataFileCC, rawCC);
	writeTextValueFile(dataFileFA, rawFA);
}

// data restricted keyword.
public void mapToFile(loc file, map[loc, map[loc,int]] dataMap) {
	if(!exists(file)) {
		writeFile(file, "");
	}
	for (key <- dataMap) {
		appendToFile(file, "<key> \n");
		for(subkey <- dataMap[key]) {
			appendToFile(file, "\t <subkey>: <dataMap[key][subkey]>\n");
		}
	}
}

// data restricted keyword.
public void mapToFile(loc file, map[loc, rel[loc,loc]] dataMap) {
	if(!exists(file)) {
		writeFile(file, "");
	}
	for (key <- dataMap) {
		appendToFile(file, "<key> \n");
		for(<a, b> <- dataMap[key]) {
			appendToFile(file, "\t <a> -\> <b>\n");
		}
	}
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

public map[loc, int] retrieveRBINHERITANCE(){
	loc dataFile = dataDir + "RBINHERITANCE/<name>";
	return readBinaryValueFile(#map[loc, int], dataFile);
}

public map[loc, int] retrieveNOM(){
	loc dataFile = dataDir + "NOM/<name>";
	return readBinaryValueFile(#map[loc, int], dataFile);
}

public map[loc, map[loc,int]] retrieveIIFA(){
	loc dataFile = dataDir + "IIFA/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}

public map[loc, map[loc,int]] retrieveCombinedMap(){
	loc dataFile = dataDir + "IICOMB/<name>";
	return readBinaryValueFile(#map[loc, map[loc,int]], dataFile);
}

public M3 retrieveModel() {
	loc dataFile = dataDir + "M3/<name>";
	return readBinaryValueFile(#M3, dataFile);
}