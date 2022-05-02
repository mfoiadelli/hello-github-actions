#!/bin/bash

validateInputs() {
	echo "Validating Inputs..."
	[[ -f ${connectionPropertiesFile} ]] && echo "::error::ERROR: Cannot find connection properties file [${connectionPropertiesFile}]." && exit 1
	[[ -d ${odiScenariosDirectory} ]] && echo "::error::ERROR: Cannot find the directory containing the ODI Scenarios to install [${odiScenariosDirectory}]." && exit 1
}

# Get the shell inputs
connectionPropertiesFile=$1
odiScenariosDirectory=$2

validateInputs

$result=$(/Users/matteofoiadelli/Documents/Development/OdiUtils/src/import-scenarios.sh -c ${connectionPropertiesFile} ${odiScenariosDirectory};  echo $?)

rm ${connectionPropertiesFile}

exit $result
