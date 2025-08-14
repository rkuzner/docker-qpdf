#!/bin/bash
scriptBaseName=$( basename "${0}" .sh )

logFile=""
logFolder=""

function set_logFolder() {
	local folderName=${1}
	if [ -z "${folderName}" ]; then
		echo "set_logFolder(): must provide a folderName as parameter"
		return
	fi
	if [ ! -d "${folderName}" ]; then
		echo "set_logFolder(): provided name is not a folder"
		return
	fi
	logFolder=${folderName}
	logFile="${logFolder}/${scriptBaseName}-$( date +%F ).log"
}

# logs a message to console AND to logfile (if available)
function log_message() {
	local message2log="${*}"
	if [ -n "${message2log}" ]; then
		timeStamp=$( date "+%Y/%m/%d %H:%M:%S,%3N" )		# ej: 2018/02/02 15:34:02,241
		if [ -n "${logFile}" ]; then
			echo "${timeStamp} | ${message2log}" | tee -a "${logFile}"
		else
			echo "${timeStamp} | ${message2log}"
		fi
	fi
}
