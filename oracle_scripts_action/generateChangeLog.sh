#!/bin/bash

################# UTILITY FUNTIONS ##################### 
validateInput() {
  # IF THE PATH WAS NOT PROVIDED EXIT
  [[ ! $1 ]] && echo "::error::ERROR: Please provide the path to the directory containing the scripts to be deployed" && exit 1
  # IF THE ENVIRONMENT WAS NOT PROVIDED EXIT
  [[ ! $2 ]] && echo "::error::ERROR: An environment name must be provided" && exit 1
}

extractDatabaseNameFromSecret() {
  if [[ ${1} =~ ^--(.+)--$ ]]
       then
            databaseName=${BASH_REMATCH[1]}
  else
       echo "::error::Error: Invalid format for parameter databaseName"
       exit 1
  fi
}

findScriptsDirectory() {
  scriptsDir=$(find . -regex "./OracleScripts/[0-9][0-9][0-9][0-9][0-9][0-9]/${1}")
  [[ ! $scriptsDir ]] && echo "::error::ERROR: directory ${scriptsDir} doesn't exist!" && exit 1
}

populateChangeLog() {
  # THE HEADER OF THE LIQUIBASE CHANGELOG FILE
  echo '<?xml version="1.0" encoding="UTF-8"?>
  <databaseChangeLog
             xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">
  ' > "${1}"

  # ENSURE TO SKIP THE FOR LOOP BODY IF NO MATCH IS FOUND (NO SQL FILES FOUND IN THE DIRECTORY)
  shopt -s nullglob extglob nocaseglob
  fileNameRegex="[0-9]{3}_${databaseName}_.+\.(sql|plsql)$"
  for scriptFilePath in ./*.sql ./*.plsql
  do
    # GET THE NAME OF THE SQL FILE
    scriptFileName=$(basename "${scriptFilePath}")

    # CHECK IF THE FILE NAME MATCHES THE PATTERN. SKIP THE FILE IF NOT.
    [[ $scriptFileName =~ $fileNameRegex ]] || continue

    # EXTRACT THE AUTHOR OF THE LAST COMMIT OF THE CURRENT FILE
    scriptLastCommitAuthor=$(git log -1 "$scriptFilePath" | grep 'Author' | cut -d ' ' -f 2)

    endDelimiter=";"
    if [ "${scriptFileName##*\.}" = "plsql" ]
     then
      endDelimiter="/"
    fi
    # CREATE THE CHANGE SET FOR THIS FILE
    changeset="            <changeSet author=\"${scriptLastCommitAuthor}\" id=\"${scriptsDirectoryName}_${scriptFileName}\">
                  <sqlFile dbms=\"oracle\"
                      encoding=\"UTF-8\"
                      endDelimiter=\"${endDelimiter}\"
                      path=\"./${scriptFileName}\"
                      relativeToChangelogFile=\"true\"
                      splitStatements=\"true\"
                      stripComments=\"true\"/>
              </changeSet>
  "
    # APPEND THE CHANGE SET TO THE CHANGE LOG FILE
    echo "${changeset}" >> ${changelogFile}
  done
  # CLOSE THE CHANGELOG FILE MAIN TAG
  echo "</databaseChangeLog>" >> ${changelogFile}
}
################# END OF UTILITY FUNTIONS #####################

##################### EXECTUTION LOGIC ########################
validateInput $1 $2 $3

# READ THE PARAMETER CONTAINING THE PATH TO THE SCRIPTS.
scriptsDirectoryName=$1
environment=$2
dbSecretName=$3
providedFileName=$4

#PARSE DATABASE NAME FROM SECRET IN INPUT 3
extractDatabaseNameFromSecret "${dbSecretName}"

# CD TO THE GITHUB WORKSPACE DIRECTORY
cd "$GITHUB_WORKSPACE" || exit 1

# LOOK FOR THE DIRECTORY TO PROCESS "./OracleScripts/<YYYYMM>/<scriptsDirectoryName>
findScriptsDirectory $scriptsDirectoryName

# IF A VALID CHANGELOG FILE HAS BEEN PROVIDED THEN BUILD THE PATH, RETURN IT WITH THE FILE NAME AND EXIT. EXIT WITH ERROR OTHERWISE
[[ -n ${providedFileName} ]] && [[ -f ${scriptsDir}/${providedFileName} ]] && echo "::set-output name=changelogFile::${providedFileName}" && echo "::set-output name=changelogDir::${scriptsDir}" && exit 0 || [[ -n ${providedFileName} ]] && echo "::error::The changelog file [ ${scriptsDir}/${providedFileName} ] does not exist! Aborting..." && exit 1

# MOVE TO THE DIRECTORY CONTAINING THE SQL SCRIPTS TO DEPLOY
cd "$scriptsDir" || exit 1
echo "Processing sql files in ${scriptsDir} directory..."

# CREATE AND INITIALIZE THE CHANGELOG FILE WRITING ITS XML HEADER
changelogFile=${environment}_${scriptsDirectoryName}_${databaseName}_changelog.xml
populateChangeLog "${changelogFile}"

# OUTPUT THE RESULT TO GITHUB ACTION AS changelogFilePath VARIABLE
echo "::set-output name=changelogFile::${changelogFile}"
echo "::set-output name=changelogDir::${scriptsDir}"

shopt -u nullglob extglob nocaseglob
exit 0
