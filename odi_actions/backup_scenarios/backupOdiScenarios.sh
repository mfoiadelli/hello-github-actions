#!/bin/bash

getOdiScenariosDirectory() {
	echo "Getting Scenarios Directory..."
	cd "$GITHUB_WORKSPACE" || exit 1
	targetDir="encrypted_scenarios"
	if [[ -z ${key} ]]
	then
		targetDir="scenarios"
	fi
	odiScenariosDirectory=$(find . -regex "./ODI/[0-9][0-9][0-9][0-9][0-9][0-9]/${ritmName}/${targetDir}")
	[[ ! $odiScenariosDirectory ]] && echo "::error::ERROR: Cannot find the directory corresponding to the provided RITM identifier (${ritmName}/${targetDir})!" && exit 1
}

generateConnectionProperties() {
	echo "Generating Connection Properties File..."
   	connectionPropertiesFile=/tmp/connection.$$.properties
	echo "url=${odiUrl}" > ${connectionPropertiesFile}
   	echo "schema=${odiSchema}" >> ${connectionPropertiesFile}
   	echo "schemaPwd=${odiSchemaPwd}" >> ${connectionPropertiesFile}
   	echo "workrep=${odiWorkRepositoryName}" >> ${connectionPropertiesFile}
   	echo "odiUser=${odiUsername}" >> ${connectionPropertiesFile}
   	echo "odiUserPwd=${odiUserPwd}" >> ${connectionPropertiesFile}
}

validateInputs() {
	echo "Validating Inputs..."
	[[ -z ${ritmName} ]] && echo "::error::ERROR: RITM identifier cannot be null. Please provide a valid RITM identifier." && exit 1
	[[ -z ${odiUrl} ]] && echo "::error::ERROR: ODI URL cannot be null. Please provide a valid ODI URL." && exit 1
	[[ -z ${odiSchema} ]] && echo "::error::ERROR: ODI Schema name cannot be null. Please provide a valid ODI Schema name." && exit 1
	[[ -z ${odiSchemaPwd} ]] && echo "::error::ERROR: ODI Schema password cannot be null. Please provide a valid password for the ODI schema." && exit 1
	[[ -z ${odiWorkRepositoryName} ]] && echo "::error::ERROR: The ODI work repository cannot be null. Please provide a valid ODI work repository name to work with." && exit 1
	[[ -z ${odiUsername} ]] && echo "::error::ERROR: ODI username cannot be null. Please provide a valid username in order to establish a connection to the ODI instance." && exit 1
	[[ -z ${odiUserPwd} ]] && echo "::error::ERROR: ODI user password cannot be null. Please provide a valid user password in order to establish a connection to the ODI instance." && exit 1
	[[ -z ${backupDirectory} ]] && echo "::error::ERROR: Backup destination directory cannot be null. Please provide a valid absolute path as the backup destination directory." && exit 1
}

# Get the shell inputs
ritmName=$1
odiUrl=$2
odiSchema=$3
odiSchemaPwd=$4
odiWorkRepositoryName=$5
odiUsername=$6
odiUserPwd=$7
key=$8
backupDirectory=~/backup/$(date '+%Y%m%d')_$ritmName

validateInputs
generateConnectionProperties
getOdiScenariosDirectory

scenarioFiles=$(find ${odiScenariosDirectory} -type f \( -iname "*.xml" \) -exec basename {} ';' | sed -E 's/^SCEN_(.+)(_V).+_([0-9]{3})\.xml$/\1\2\3/g')
grepPattern=$(echo ${scenarioFiles} | sed 's/ /|/')
backupListFile=/tmp/scenarioBackupList.$$.txt
echo "------------------------------------------------"
echo "Generating the list of ODI Scenarios to backup"
/Users/matteofoiadelli/Documents/Development/OdiUtils/src/list-objects.sh -c ${connectionPropertiesFile} -t SCENARIO | grep -i -E "${grepPattern}" > ${backupListFile}

echo "The following Odi Scenarios will be backed up: "
cat ${backupListFile}
echo "------------------------------------------------"
echo ""

echo "------------------------------------------------"
echo "Backing up ODI Scenarios to directory ${backupDirectory}"
if [[ -z ${key} ]]
then 
	result=$(/Users/matteofoiadelli/Documents/Development/OdiUtils/src/export-scenarios.sh -c ${connectionPropertiesFile} -f ${backupListFile} -o ${backupDirectory}; echo $?)
else
	result=$(/Users/matteofoiadelli/Documents/Development/OdiUtils/src/export-scenarios.sh -c ${connectionPropertiesFile} -f ${backupListFile} -o ${backupDirectory} -k ${key}; echo $?)
fi
[[ ${result} -eq 0 ]] && echo " Done!" || echo "::error::ERROR: Backup process failed. Check the logs above for further details."
echo "------------------------------------------------"

rm ${backupListFile} ${connectionPropertiesFile}

exit $result
