module util::Settings

import Prelude;

// purpose of this module is to set thresholds for locations in a central location. 

bool debugMode = false;
int overrideThreshold = 3; 
int protectedMemberThreshold = 3;
int couplingThreshold = 3;
bool consoleMode = true;
bool logToProjectLogs = true;
bool results = false;

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

public bool getDebugMode() {
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