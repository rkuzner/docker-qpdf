#!/bin/bash

# import log_message function
scriptFolder=$( cd "$( dirname "${0}" )" && pwd )
scriptBaseName=$( basename "${0}" .sh )
configFileName="${scriptFolder}/${scriptBaseName}.conf"
if [ -f "${configFileName}" ]; then
	# shellcheck disable=SC1090
	source "${configFileName}"
fi
if [ -n "${TOOL_NAME}" ]; then
	scriptBaseName="${scriptBaseName}-"$( echo ${TOOL_NAME} | tr "[:upper:]" "[:lower:]" )
fi
DEFAULT_LOG_FOLDER="/logs"
DEFAULT_SOURCE_FOLDER="/source"
DEFAULT_TARGET_FOLDER="/target"
DEFAULT_PROCESSED_FOLDER="/processed"
DEFAULT_KEEP_SOURCEFILE="false"
DEFAULT_MOVE_UNENCRYPTED="true"

source "${scriptFolder}/log-message.sh"
set_logFolder "${LOG_FOLDER:-${DEFAULT_LOG_FOLDER}}"
set_logFileBaseName "${scriptBaseName}"

if [ -f "${configFileName}" ]; then
	log_message "Found Config file!"
else
	log_message "Config file not found: ${configFileName}, using default values"
fi

SOURCE_FOLDER="${SOURCE_FOLDER:-${DEFAULT_SOURCE_FOLDER}}"
TARGET_FOLDER="${TARGET_FOLDER:-${DEFAULT_TARGET_FOLDER}}"
PROCESSED_FOLDER="${PROCESSED_FOLDER:-${DEFAULT_PROCESSED_FOLDER}}"
KEEP_SOURCEFILE="${KEEP_SOURCEFILE:-${DEFAULT_KEEP_SOURCEFILE}}"
MOVE_UNENCRYPTED="${MOVE_UNENCRYPTED:-${DEFAULT_MOVE_UNENCRYPTED}}"

log_message "Checking folders..."
if [ ! -d "${SOURCE_FOLDER}" ]; then
	log_message_and_exit 11 "Invalid SOURCE_FOLDER: ${SOURCE_FOLDER}"
fi
if [ ! -r "${SOURCE_FOLDER}" ]; then
	log_message_and_exit 12 "Can not read from SOURCE_FOLDER: ${SOURCE_FOLDER}"
fi
if [ ! -w "${SOURCE_FOLDER}" ]; then
	log_message_and_exit 13 "Can not write on SOURCE_FOLDER: ${SOURCE_FOLDER}"
fi
if [ ! -d "${TARGET_FOLDER}" ]; then
	log_message_and_exit 14 "Invalid TARGET_FOLDER: ${TARGET_FOLDER}"
fi
if [ ! -r "${TARGET_FOLDER}" ]; then
	log_message_and_exit 15 "Can not read from TARGET_FOLDER: ${TARGET_FOLDER}"
fi
if [ ! -w "${TARGET_FOLDER}" ]; then
	log_message_and_exit 16 "Can not write on TARGET_FOLDER: ${TARGET_FOLDER}"
fi
if [ ! -d "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 17 "Invalid PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
if [ ! -r "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 18 "Can not read from PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
if [ ! -w "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 19 "Can not write on PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
log_message "Found valid folders!"

log_message "Checking for passwords file"
if [ -z "${PASSWORDS_FILENAME}" ]; then
	log_message_and_exit 11 "No PASSWORDS_FILENAME environment var Found!"
fi
log_message "Found PASSWORDS_FILENAME environment var!"

if [ ! -f "${PASSWORDS_FILENAME}" ]; then
	log_message_and_exit 12 "Passwords file not-found: ${PASSWORDS_FILENAME}"
fi
log_message "Found Passwords file!"

lineCount=$( grep -e plain -e base64 "${PASSWORDS_FILENAME}" | wc -l )
passwordCount=$( expr ${lineCount} + 0 )
if [ ${passwordCount} -eq 0 ]; then
	log_message_and_exit 13 "No Passwords found on file ${PASSWORDS_FILENAME}"
fi
log_message "Found ${passwordCount} Passwords in file!"

log_message "Checking for source files"
folderContents=$( ls -1 "${SOURCE_FOLDER}" )
if [ -z "${folderContents}" ]; then
	log_message_and_exit 0 "No files found on source folder. Nothing to do!"
fi

log_message "Preparing passwords list"
passwordList=$( grep -e plain "${PASSWORDS_FILENAME}" | cut -f2 -d"," )
passwordList="${passwordList}"$'\n'$( grep -e base64 "${PASSWORDS_FILENAME}" | cut -f2 -d"," | base64 --decode )

log_message "Iterating source files: ${SOURCE_FOLDER}"
#log_message "DEBUG: folderContents: ${folderContents}"
# must be able to iterate on filenames that have spaces on them
originalIFS="${IFS}"
IFS=$'\n'
for individualFile in ${folderContents}; do
	#log_message "DEBUG: individualFile: ${SOURCE_FOLDER}/${individualFile}"

	if [ -d "${SOURCE_FOLDER}/${individualFile}" ]; then
		log_message "Found a directory! Ignoring: ${individualFile}"
	fi
	if [ ! -d "${SOURCE_FOLDER}/${individualFile}" ]; then
		# check if file is encrypted
		qpdf --is-encrypted "${SOURCE_FOLDER}/${individualFile}" 2>&1 | tee -a "$( get_logFileName )"
		#qpdf @${paramFileName}
		isEncryptedResult=${?}
		if [ ${isEncryptedResult} -eq 2 ]; then
			log_message "File is NOT encrypted: ${individualFile}"
			# if decrypt successful , remove original (if aplicable)
			if [ "${MOVE_UNENCRYPTED}" == "true" ] ; then
				log_message "Moving to target folder..."
				mv "${SOURCE_FOLDER}/${individualFile}" "${TARGET_FOLDER}"
			fi
		elif [ ${isEncryptedResult} -eq  1 ]; then
			# Should not happen, because of unused error Code
			log_message "Unused Error Code!"
		elif [ ${isEncryptedResult} -eq 0 ]; then
			log_message "File IS encrypted: ${individualFile}"

			log_message "Trying Passwords on file..."
			#log_message "DEBUG: passwordList: ${passwordList}"
			for individualPassword in ${passwordList}; do
				if [ -f "${SOURCE_FOLDER}/${individualFile}" ]; then
					#log_message "DEBUG: individualPassword: ${individualPassword}"
					qpdf --requires-password --password=${individualPassword} "${SOURCE_FOLDER}/${individualFile}" 2>&1 | tee -a "$( get_logFileName )"
					requirePasswordResult=${?}
					if [ ${requirePasswordResult} -eq 0 ]; then
						# Should not happen, because of previous validations
						log_message "Password Mismatch!"
					elif [ ${requirePasswordResult} -eq 1 ]; then
						# Should not happen, because of unused error Code
						log_message "Unused Error Code!"
					elif [ ${requirePasswordResult} -eq 2 ]; then
						# Should not happen, because of previous validations
						log_message "File is NOT encrypted!"
					elif [ ${requirePasswordResult} -eq 3 ]; then
						log_message "Found password Match with file!"

						qpdf --decrypt --password=${individualPassword} "${SOURCE_FOLDER}/${individualFile}" "${TARGET_FOLDER}/${individualFile}" 2>&1 | tee -a "$( get_logFileName )"
						decryptResult=${?}
						if [ ${decryptResult} -eq 0 ]; then
							# should match target's timestamps with source's timestamps
							log_message "Updating target's timestamps..."
							touch -r "${SOURCE_FOLDER}/${individualFile}" "${TARGET_FOLDER}/${individualFile}"

							# if decrypt successful , remove original (if aplicable)
							if [ "${KEEP_SOURCEFILE}" == "true" ] ; then
								log_message "Moving source file to processed folder..."
								mv -n "${SOURCE_FOLDER}/${individualFile}" "${PROCESSED_FOLDER}"
							fi
							if [ "${KEEP_SOURCEFILE}" == "false" ] ; then
								log_message "Removing source file..."
								rm -f "${SOURCE_FOLDER}/${individualFile}"
							fi
						else
							log_message "Could not decrypt file! (qpdf errCode: ${decryptResult})"
						fi
					fi # evaluate requirePasswordResult
				fi # file exists? or was decrypted with previous password?
			done
		fi # evaluate isEncryptedResult
	fi # evaluate isFile (notFolder)
done
# restore originalIFS
IFS="${originalIFS}"
