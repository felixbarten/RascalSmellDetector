module util::Settings

import Prelude;

// purpose of this module is to set thresholds for locations in a central location. 

bool debugMode = false;
int overrideThreshold = 3; 
int protectedMemberThreshold = 3;

public void setDebugMode(bool b) {
	if(b) println("Debugging mode is now enabled");
	debugMode = b;
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