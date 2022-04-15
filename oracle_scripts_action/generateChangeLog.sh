#!/usr/bin/env bash

usage() {
     # Display Help
     echo
     echo "generateChangeLog.sh"
     echo "Utility for generating Liquibase changelog xml file for the script in the directory named as the RITM provided."
     echo "The utility will return to the github action the directory containing the changelog file and its name."
     echo "If an existing changelog file is provided as third parameter, this command will return the path of the directory containing and the file's name to the github action."
     echo
     echo "Syntax: generateChangeLog.sh <RITM_NAME> <ENVIRONMENT> <DATABASE_NAME> [EXISTING_CHANGELOG_FILE]"
     echo

     exit 1
}

# READ THE PARAMETER CONTAINING THE PATH TO THE SCRIPTS.
ritm=$1
environment=$2
databaseName=$3
providedFileName=$4

# IF THE PATH WAS NOT PROVIDED EXIT
[[ ! $ritm ]] && echo "::error::ERROR: Please provide the path to the directory containing the scripts to be deployed" && exit 1
[[ ! $environment ]] && echo "::error::ERROR: Please provide the path to the directory containing the scripts to be deployed" && exit 1

# CD TO THE GITHUB WORKSPACE DIRECTORY
cd ${GITHUB_WORKSPACE}

# LOOK FOR THE DIRECTORY TO PROCESS "./OracleScripts/<YYYYMM>/<RITM>
scriptsDir=$(find . -regex "./OracleScripts/[0-9][0-9][0-9][0-9][0-9][0-9]/${ritm}")
[[ ! $scriptsDir ]] && echo "::error::ERROR: directory ${scriptsDir} doesn't exist!" && exit 1

echo "::warning::CD to DIR ${scriptsDir}"
[[ -n ${providedFileName} ]] && echo "FILE NON VUOTO" || echo "FILE VUOTO"
# IF A VALID CHANGELOG FILE HAS BEEN PROVIDED THEN BUILD THE PATH, RETURN IT WITH THE FILE NAME AND EXIT. EXIT WITH ERROR OTHERWISE
[[ -n ${providedFileName} ]] && [[ -f ${scriptsDir}/${providedFileName} ]] && echo "::set-output name=changelogFile::${providedFileName}" && echo "::set-output name=changelogDir::${scriptsDir}" && exit 0 || [[ -n ${providedFileName} ]] && echo "::error::The changelog file [ ${scriptsDir}/${providedFileName} ] does not exist! Aborting..." && exit 1

# MOVE TO THE DIRECTORY CONTAINING THE SQL SCRIPTS FOR THE RITM
echo "::warning::CD to DIR ${scriptsDir}"
cd "$scriptsDir"
echo "Processing sql files in ${scriptsDir} directory..."

# THE HEADER OF THE LIQUIBASE CHANGELOG FILE
CHANGELOG_HEADER='<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
           xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd">
'

# CREATE AND INITIALIZE THE CHANGELOG FILE WRITING ITS XML HEADER
changelogFile=${environment}_${ritm}_changelog.xml
echo "${CHANGELOG_HEADER}" > ${changelogFile}

# ENSURE TO SKIP THE FOR LOOP BODY IF NO MATCH IS FOUND (NO SQL FILES FOUND IN THE DIRECTORY)
shopt -s nullglob extglob nocaseglob
fileNameRegex="[0-9]{3}_${databaseName}_.+\.sql$"
for scriptFilePath in ./*.sql ./*.plsql
do
     echo $(basename "${scriptFilePath}")
     if [[ $(basename "${scriptFilePath}") =~ $fileNameRegex ]] 
          then
               echo "${scriptFilePath} matches"
     fi
done
for scriptFilePath in ./*.sql ./*.plsql
do

  # GET THE NAME OF THE SQL FILE AND CHECK IF IT MATCHES THE DB NAME BASED PATTERN 
  scriptFileName=$(basename "${scriptFilePath}")
  [[ $scriptFileName =~ $fileNameRegex ]] || continue
  
  # EXTRACT THE AUTHOR OF THE LAST COMMIT OF THE CURRENT FILE
  scriptLastCommitAuthor=$(git log -1 "$scriptFilePath" | grep 'Author' | cut -d ' ' -f 2)
  
  endDelimiter=";"
  if [ "${scriptFileName##*\.}" = "plsql" ]
   then
    endDelimiter="/"
  fi
  # CREATE THE CHANGE SET FOR THIS FILE
  changeset="            <changeSet author=\"${scriptLastCommitAuthor}\" id=\"${ritm}_${scriptFileName}\">
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

# OUTPUT THE RESULT TO GITHUB ACTION AS changelogFilePath VARIABLE
echo "::set-output name=changelogFile::${changelogFile}"
echo "::set-output name=changelogDir::${scriptsDir}"

shopt -u nullglob extglob nocaseglob

exit 0
