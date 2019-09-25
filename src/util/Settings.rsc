module util::Settings

import Prelude;

// purpose of this module is to set settings in a central location. 

// [detector]
bool debugMode = false;
bool consoleMode = true;
bool logToProjectLogs = true;
bool results = false;
bool storeData = true;
// [rb]
bool rbEnabled = true;
int overrideThreshold = 3; 
int protectedMemberThreshold = 3;
// [ii]
bool iiEnabled = true;
int couplingThreshold = 3;

public void setDebugMode(bool b) {
	if(b) println("Debugging mode is now enabled");
	debugMode = b;
}

public void setConsoleMode(bool b) {
	consoleMode = b;
}

public void setProjectLogging(bool b) {
	logToProjectLogs = b;
}

public void setPrintIntermediaryResults(bool b) {
	results = b;
}

public void setStoreData(bool b) {
	storeData = b;
}

public void setOverrideThreshold(int n) {
	overrideThreshold = n;
}

public void setProtectedMemberThreshold(int n) {
	protectedMemberThreshold = n;
}

public void setCouplingThreshold(int n) {
	couplingThreshold = n;
}

public void setRBEnabled(bool b) {
	rbEnabled = b;
}

public void setIIEnabled(bool b) {
	iiEnabled = b;
}
public bool getDebugMode() {
	return debugMode;
}

public bool getDebuggingMode() {
	return debugMode;
}

public int getBequestOverrideThreshold() {
	return overrideThreshold;
}

public int getProtectedMemberThreshold() {
	return protectedMemberThreshold;
}

public bool getConsoleMode() {
	return consoleMode;
}

public bool getProjectLogging() {
	return logToProjectLogs;
}

public int getCouplingThreshold() {
	return couplingThreshold; 
}

public bool getPrintIntermediaryResults() {
	return results;
}

public bool getStoreData() {
	return storeData;
}

public bool getDataStorage() {
	return storeData;
}

public bool getRBEnabled() {
	return rbEnabled;
}

public bool getIIEnabled() {
	return iiEnabled;
}

public void enableIIDetector() {
	iiEnabled = true;
}

public void disableIIDetector(){
	iiEnabled = false;
}