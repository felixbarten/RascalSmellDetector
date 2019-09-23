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

public void storeCC(loc dataDir, map[int, int] results){
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

public tuple[rel[loc,int],int,int,int,real] retrieveLOC(){
	loc dataFile = dataDir + "LOC/<name>";
	tuple[rel[loc,int],int,int,int,real] results = <{}, 0,0,0,0.0>;
	results = readBinaryValueFile(#tuple[rel[loc,int],int,int,int,real], dataFile);
	return results;
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

public void storeII(){
	debug("Storing II data");
}


public void storeIIClassCalls(map[loc, map[loc, int]] results){
	debug("Storing II ClassCalls data");
	loc dataFile = dataDir + "IICC/<name>";
	writeBinaryValueFile(dataFile, results);

}

public void storeIIFieldAccess(map[loc, map[loc, int]] results){
	debug("Storing II FA data");
	loc dataFile = dataDir + "IIFA/<name>";
	writeBinaryValueFile(dataFile, results);
}
