#!/bin/bash
defaultLogFileBaseName=$( basename "${0}" .sh )
defaultLogFolder=$( cd "$( dirname "${0}" )" && pwd )

logFileBaseName="${logFileBaseName:-${defaultLogFileBaseName}}"
logFolder="${logFolder}:-${defaultLogFolder}"

COLUMNS=180

function set_logFileBaseName() {
	local fileBaseName="${*}"
	if [ -z "${fileBaseName}" ]; then
		echo "set_logFileBaseName(): must provide a fileBaseName as parameter"
		return
	fi
	logFileBaseName="${fileBaseName}"
	echo "set_logFileBaseName(): logFileBaseName will be ${fileBaseName}"
}

function set_logFolder() {
	local folderName="${*}"
	if [ -z "${folderName}" ]; then
		echo "set_logFolder(): must provide a folderName as parameter"
		return
	fi
	if [ ! -d "${folderName}" ]; then
		echo "set_logFolder(): provided name is not a folder"
		return
	fi
	logFolder="${folderName}"
	echo "set_logFolder(): logFolder will be ${logFolder}"
}

function get_logFileName() {
	echo "${logFolder}/${logFileBaseName}-$( date +%F ).log"
}

# logs a message to console AND to logFileBaseName (if available)
function log_message() {
	local message2log="${*}"
	if [ -n "${message2log}" ]; then
		timeStamp=$( date "+%Y/%m/%d %H:%M:%S,%3N" )		# ej: 2018/02/02 15:34:02,241
		if [ -n "${logFileBaseName}" ]; then
			# we have a target logFileBaseName!
			local logFile="${logFolder}/${logFileBaseName}-$( date +%F ).log"
			echo "${timeStamp} | ${message2log}" | tee -a "${logFile}"
			return
		fi
		# we have NO target logFile!
		echo "${timeStamp} | ${message2log}"
	fi
}

# logs a message to console AND to logFileBaseName (if available) THEN exits with provided code
function log_message_and_exit() {
	local exitCode=$( expr "${1}" + 0 ); shift
	local message2log="${*}"
	log_message "${message2log}"
	exit ${exitCode}
}
