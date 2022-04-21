#!/bin/bash

getOdiObjectsDirectory() {
	# MOVE TO THE GITHUB CHECKOUT DIR.
	cd "$GITHUB_WORKSPACE" || exit 1
	echo $(pwd)
	# FIND THE PATH TO THE ODI OBJECTS BASED ON THE RITM PROVIDED
	odiObjectsDirectory=$(find . -regex "./ODI/[0-9][0-9][0-9][0-9][0-9][0-9]/${ritmName}/objects")
	echo "Directory ${odiObjectsDirectory} found."
	# IF THE DIRECTORY HASN'T BEEN FOUND THEN LOG THE ERROR AND EXIT
	[[ ! $odiObjectsDirectory ]] && echo "::error::ERROR: Cannot find the directory corresponding to the provided RITM identifier (${ritmName})!" && exit 1
}

generateConnectionProperties() {
   	connectionPropertiesFile=/tmp/connection.properties
	echo "url=${odiUrl}" > ${connectionPropertiesFile}
   	echo "schema=${odiSchema}" >> ${connectionPropertiesFile}
   	echo "schemaPwd=${odiSchemaPwd}" >> ${connectionPropertiesFile}
   	echo "workrep=${odiWorkRepositoryName}" >> ${connectionPropertiesFile}
   	echo "odiUser=${odiUsername}" >> ${connectionPropertiesFile}
   	echo "odiUserPwd=${odiSchemaPwd}" >> ${connectionPropertiesFile}
}

validateInputs() {
	echo "${ritmName} - ${odiUrl} - ${odiSchema} - ${odiSchemaPwd} - ${odiWorkRepositoryName} - ${odiUsername} - ${odiSchemaPwd}"
	[[ -z ${ritmName} ]] && echo "::error::ERROR: RITM identifier cannot be null. Please provide a valid RITM identifier." && exit 1
	[[ -z ${odiUrl} ]] && echo "::error::ERROR: ODI URL cannot be null. Please provide a valid ODI URL." && exit 1
	[[ -z ${odiSchema} ]] && echo "::error::ERROR: ODI Schema name cannot be null. Please provide a valid ODI Schema name." && exit 1
	[[ -z ${odiSchemaPwd} ]] && echo "::error::ERROR: ODI Schema password cannot be null. Please provide a valid password for the ODI schema." && exit 1
	[[ -z ${odiWorkRepositoryName} ]] && echo "::error::ERROR: The ODI work repository cannot be null. Please provide a valid ODI work repository name to work with." && exit 1
	[[ -z ${odiUsername} ]] && echo "::error::ERROR: ODI username cannot be null. Please provide a valid username in order to establish a connection to the ODI instance." && exit 1
	[[ -z ${odiSchemaPwd} ]] && echo "::error::ERROR: ODI user password cannot be null. Please provide a valid user password in order to establish a connection to the ODI instance." && exit 1
}

# Get the shell inputs
ritmName=$1
odiUrl=$2
odiSchema=$3
odiSchemaPwd=$4
odiWorkRepositoryName=$5
odiUsername=$6
odiUserPwd=$7

echo -n "Validating Inputs..."
validateInputs
echo " Done!"
echo -n "Generating Connection Properties File..."
generateConnectionProperties
echo " Done!"
echo -n "Getting Objects Directory..."
getOdiObjectsDirectory
echo " Done!"

echo -n "Executing import-objects shell..."
result=$(/Users/matteofoiadelli/Documents/Development/OdiUtils/src/import-objects.sh -c ${connectionPropertiesFile} ${odiObjectsDirectory}; echo $?)
[[ ${result} -eq 0 ]] && echo " Done!" || echo "::error:: Failed!"
echo -n "Cleaning up..."
rm ${connectionPropertiesFile}
echo " Done!"
exit $result
