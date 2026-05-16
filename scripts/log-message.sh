#!/bin/bash
# v0.3.1 by RK on 2026-05-15

defaultLogFileBaseName=$( basename "${0}" .sh )
defaultLogFolder=$( cd "$( dirname "${0}" )" && pwd )

logFileBaseName="${logFileBaseName:-${defaultLogFileBaseName}}"
logFolder="${logFolder:-${defaultLogFolder}}"
logRotateSubFolder="old"
logRotateAgeDays=7

export COLUMNS=180

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

function get_logRotateFolderName() {
	local whatYear="$( date +%Y )"
	if [ -n "${1}" ]; then
		whatYear="${1}"
	fi
	echo "${logFolder}/${logRotateSubFolder}/${whatYear}"
}

function get_logRotateAgeSeconds() {
	echo "$(( $( date +%s ) - $(( ${logRotateAgeDays} * 24 * 60 * 60 )) ))"
}

function log_rotate() {
	local dryRun=""
	[ "${1}" == "--dry-run" ] && dryRun=1
	[ "${dryRun}" ] && log_message "[dry-run mode — no log files will be rotated]"

	for file in "${logFolder}"/"${logFileBaseName}"-*.log; do
		fileAgeSeconds="$( date -r "${file}" +%s )"
		rotateAgeSeconds="$( get_logRotateAgeSeconds )"
		if [ "${fileAgeSeconds}" -lt "${rotateAgeSeconds}" ]; then
			logRotateTargetFolder="$( get_logRotateFolderName "$( date -r "${file}" +%Y )" )"

			if [ "${dryRun}" ]; then
				log_message "[dry-run] mv ${file}  →  ${logRotateTargetFolder}"
			else
				log_message "rotating ${file}  to  ${logRotateTargetFolder}"
				mkdir -p "${logRotateTargetFolder}"
				mv "${file}" "${logRotateTargetFolder}"
			fi

		fi
	done
}

# logs a message to console AND to logFileBaseName (if available)
function log_message() {
	local message2log="${*}"
	if [ -n "${message2log}" ]; then
		timeStamp=$( date "+%Y/%m/%d %H:%M:%S,%3N" )		# ej: 2018/02/02 15:34:02,241
		if [ -n "${logFileBaseName}" ]; then
			# we have a target logFileBaseName!
			echo "${timeStamp} | ${message2log}" | tee -a "$( get_logFileName )"
			return
		fi
		# we have NO target logFile!
		echo "${timeStamp} | ${message2log}"
	fi
}

# logs a message to console AND to logFileBaseName (if available) THEN exits with provided code
function log_message_and_exit() {
	local exitCode
	exitCode=$(( ${1} + 0 )); shift
	local message2log="${*}"
	log_message "${message2log}"
	exit "${exitCode}"
}
