#!/bin/bash

# import log_message function
scriptFolder=$( cd "$( dirname "${0}" )" && pwd )
source "${scriptFolder}/log-message.sh"

DEFAULT_LOG_FOLDER="/logs"
DEFAULT_SOURCE_FOLDER="/source"
DEFAULT_TARGET_FOLDER="/target"
DEFAULT_KEEP_SOURCEFILE="false"
DEFAULT_MOVE_UNENCRYPTED="true"

SOURCE_FOLDER=""
TARGET_FOLDER=""
KEEP_SOURCEFILE=""
MOVE_UNENCRYPTED=""


configFileName="${scriptFolder}/${scriptBaseName}.conf"
if [ -f "${configFileName}" ]; then
	log_message "Found Config file!"
	# shellcheck disable=SC1090
	source "${configFileName}"

else
  log_message "Config file not found: ${configFileName}, using default values"
fi

if [ -z "${LOG_FOLDER}" ]; then
	LOG_FOLDER="${DEFAULT_LOG_FOLDER}"
fi
set_logFolder ${LOG_FOLDER}
if [ -z "${SOURCE_FOLDER}" ]; then
SOURCE_FOLDER="${DEFAULT_SOURCE_FOLDER}"
fi
if [ -z "${TARGET_FOLDER}" ]; then
TARGET_FOLDER="${DEFAULT_TARGET_FOLDER}"
fi
if [ -z "${KEEP_SOURCEFILE}" ]; then
KEEP_SOURCEFILE="${DEFAULT_KEEP_SOURCEFILE}"
fi
if [ -z "${MOVE_UNENCRYPTED}" ]; then
MOVE_UNENCRYPTED="${DEFAULT_MOVE_UNENCRYPTED}"
fi

log_message "Checking for passwords file"
if [ -z "${PASSWORDS_FILENAME}" ]; then
  log_message "No PASSWORDS_FILENAME environment var Found!"
  exit 11
fi
log_message "Found PASSWORDS_FILENAME environment var!"

if [ ! -f "${PASSWORDS_FILENAME}" ]; then
  log_message "Passwords file not-found: ${PASSWORDS_FILENAME}"
  exit 12
fi
log_message "Found Passwords file!"

lineCount=$( grep -e plain -e base64 "${PASSWORDS_FILENAME}" | wc -l )
passwordCount=$( expr ${lineCount} + 0 )
if [ ${passwordCount} -eq 0 ]; then
  log_message "No Passwords found on file ${PASSWORDS_FILENAME}"
  exit 13
fi
log_message "Found ${passwordCount} Passwords in file!"

log_message "Checking for source files"
folderContents=$( ls -1 ${SOURCE_FOLDER} )
if [ -z "${folderContents}" ]; then
  log_message "No files found on source folder."
  log_message "Nothing to do!"
  exit 0
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

	# check if file is encrypted
	qpdf --is-encrypted "${SOURCE_FOLDER}/${individualFile}"
	#qpdf @${paramFileName}
	isEncryptedResult=${?}
	if [ ${isEncryptedResult} -eq 2 ]; then
		log_message "File is NOT encrypted: ${individualFile}"
		# if decrypt successful , remove original (if aplicable)
		if [ "${MOVE_UNENCRYPTED}" == "true" ] ; then
			log_message "Moving to target folder: ${TARGET_FOLDER}"
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
				qpdf --requires-password --password=${individualPassword} "${SOURCE_FOLDER}/${individualFile}"
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

					qpdf --decrypt --password=${individualPassword} "${SOURCE_FOLDER}/${individualFile}" "${TARGET_FOLDER}/${individualFile}"
					decryptResult=${?}
					if [ ${decryptResult} -eq 0 ]; then
						# if decrypt successful , remove original (if aplicable)
						if [ "${KEEP_SOURCEFILE}" == "false" ] ; then
							rm -f "${SOURCE_FOLDER}/${individualFile}"
						fi
					else
						log_message "Could not decrypt file! (qpdf errCode: ${decryptResult})"
					fi
				fi # evaluate requirePasswordResult
			fi # file exists?
		done
	fi # evaluate isEncryptedResult
done
# restore originalIFS
IFS="${originalIFS}"
