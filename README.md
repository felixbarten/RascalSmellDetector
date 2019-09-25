# RascalSmellDetector

Part of master's project involving Code Smell detection on Python and Java source code.

## Using the detector

The detector can be used in multiple ways. Either with projects directly in Eclipse or from a directory.

`detectproject(loc project);` detects a single project

Example:

`detectProject(|project://TestProject);`

`main(loc directory);` walks through all subdirectories and detects smells in each project.

Example:

`main(|file:///C/projects/|)`

`gatherDataset(loc directory, int min = 1, int max = 5)` runs main with all permutations of min and max values. This method is very time consuming as main will be called (max-min)^2 times with each run taking possibly hours depending on the amount of java projects contained in the directory.

Example:

`gatherDataset(|home:///projects)`

## What does it detect?

The rascal smell detector can detect the Inappropriate intimacy and Refused Bequest code smells. Due to the lack of absolute values found in literature the detector can be configured with multiple settings.

Refused Bequest has two settings: Overrides and parentProtectedMembers. They can be adjusted to make the detector more or less strict.


## Settings

TODO
