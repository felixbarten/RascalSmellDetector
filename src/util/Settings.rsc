module util::Settings

import Prelude;

// purpose of this module is to set settings in a central location. 

// [detector]
bool debugMode = false;
bool debugLogOnly = false;
bool consoleMode = true;
bool logToProjectLogs = true;
// verbose logging
bool printAll = false;
bool storeData = true;
// use lanza/marinescu avgs
bool useMetricsAverages = true;
// [rb]
bool rbEnabled = true;
int overrideLowThreshold = 2;
int overrideHighThreshold = 5; 
int protectedMemberLowThreshold = 2;
int protectedMemberHighThreshold = 5; 

// Lanza & Marinescu. 
real javaAMWAVG = 2.0;
int javaWMCAVG = 14;
int javaNOMAVG = 7;
int javaLOCAVG = 70;

// [ii]
bool iiEnabled = true;
int couplingThreshold = 3;

str prefix = "[SETTINGS] ";

public void setDebugMode(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Debugging mode is now <status>.");
	debugMode = b;
}

public void setDebugLogOnly(bool b) {
	str status = b ? "no" : "yes";
	println("<prefix> Display debugging messages in console: <status>.");
	debugLogOnly = b;
}

public void setConsoleMode(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Console logging mode is now <status>.");
	consoleMode = b;
}

public void setProjectLogging(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Project logging mode is now <status>.");
	logToProjectLogs = b;
}

public void setVerboseLogging(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Verbose logging mode is now <status>.");
	printAll = b;
}

public void setStoreData(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Data storage mode is now <status>.");
	storeData = b;
}

public void setUseMetricsAverages(bool b) {
	str status = b ? "enabled" : "disabled";
	println("<prefix> Lanza and Marinescu averages <status>.");
	useMetricsAverages = b;
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

public real getAMWAvg() {
	return javaAMWAVG;
}

public int getWMCAvg() {
	return javaWMCAVG;
}

public int getNOMAvg() {
	return javaNOMAVG;
}

public int getLOCAvg() {
	return javaLOCAVG;
}

public bool getUseMetricsAverages() {
	return useMetricsAverages;
}

public bool getVerboseLoggingMode() {
	return printAll;
}

public bool getDebugMode() {
	return debugMode;
}

public bool getDebuggingMode() {
	return debugMode;
}

public bool getDebuggingLogOnly() {
	return debugLogOnly;
}

public int getBequestHighOverrideThreshold() {
	return overrideHighThreshold;
}

public int getBequestLowOverrideThreshold() {
	return overrideLowThreshold;
}

public int getProtectedMemberHighThreshold() {
	return protectedMemberHighThreshold;
}


public int getProtectedMemberLowThreshold() {
	return protectedMemberLowThreshold;
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
	return printAll;
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

public void enableDebugging() {
	setDebugMode(true);
}
public void enableDebugging(bool log) {
	setDebugMode(true);
	setDebugLogOnly(log);
}

public void enableLanzaMarinescuAvg() {
	setUseMetricsAverages(true);
}

public void disableLanzaMarinescuAvg() {
	setUseMetricsAverages(false);
}

public void enableIIDetector() {
	iiEnabled = true;
}

public void disableIIDetector(){
	iiEnabled = false;
}

public void enableRBDetector() {
	rbEnabled = true;
}

public void disableRBDetector(){
	rbEnabled = false;
}

public void enablePrintAll() {
	printAll = true;
}

public void enableVerboseLogging() {
	setVerboseLogging(true);
}