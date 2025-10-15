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

log_message "-+*+- -+*+- -+*+- -+*+- -+*+-"
log_message "-+*+-  Tool-Run  START  -+*+-"
log_message "-+*+- -+*+- -+*+- -+*+- -+*+-"

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
log_message "Using SOURCE_FOLDER: ${SOURCE_FOLDER}"

if [ ! -d "${TARGET_FOLDER}" ]; then
	log_message_and_exit 14 "Invalid TARGET_FOLDER: ${TARGET_FOLDER}"
fi
if [ ! -r "${TARGET_FOLDER}" ]; then
	log_message_and_exit 15 "Can not read from TARGET_FOLDER: ${TARGET_FOLDER}"
fi
if [ ! -w "${TARGET_FOLDER}" ]; then
	log_message_and_exit 16 "Can not write on TARGET_FOLDER: ${TARGET_FOLDER}"
fi
log_message "Using TARGET_FOLDER: ${TARGET_FOLDER}"

if [ ! -d "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 17 "Invalid PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
if [ ! -r "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 18 "Can not read from PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
if [ ! -w "${PROCESSED_FOLDER}" ]; then
	log_message_and_exit 19 "Can not write on PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
fi
log_message "Using PROCESSED_FOLDER: ${PROCESSED_FOLDER}"
log_message "Found valid folders!"

log_message "Using KEEP_SOURCEFILE: ${KEEP_SOURCEFILE}"
log_message "Using MOVE_UNENCRYPTED: ${MOVE_UNENCRYPTED}"

log_message "Checking for passwords file"
if [ -z "${PASSWORDS_FILENAME}" ]; then
	log_message_and_exit 11 "No PASSWORDS_FILENAME environment var Found!"
fi
log_message "Found PASSWORDS_FILENAME environment var!"

if [ ! -f "${PASSWORDS_FILENAME}" ]; then
	log_message_and_exit 12 "Passwords file not-found: ${PASSWORDS_FILENAME}"
fi
log_message "Using PASSWORDS_FILENAME: ${PASSWORDS_FILENAME}"
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

# encapsulates single password evaluation over a single file, useful within a for-loop
function try_password_on_file() {
	local thePassword=""
	local sourceFullFileName=""
	local targetFullFileName=""
	local requirePasswordResult=0
	local decryptResult=0

	# process received params
	while [[ ${#} -gt 0 ]]; do
  		case ${1} in
			-ep|--emptyPassword)
			thePassword=""
			#log_message "try_password_on_file(): Using empty password"
			shift	# argument key
			;;
			-p|--password)
			thePassword="${2}"
			#log_message "try_password_on_file(): Using non-empty password"
			shift	# argument key
			shift	# argument value
			;;
			-sf|--sourceFile)
			sourceFullFileName="${2}"
			#log_message "try_password_on_file(): Using sourceFullFileName: ${sourceFullFileName}"
			shift	# argument key
			shift	# argument value
			;;
			-tf|--targetFile)
			targetFullFileName="${2}"
			#log_message "try_password_on_file(): Using targetFullFileName: ${targetFullFileName}"
			shift	# argument key
			shift	# argument value
			;;
			-*|--*)
			log_message "try_password_on_file(): unknown option: ${1}"
			return
			;;
		esac
	done

	# do some validations before working on decrypting files
	# check if the sourcefile exists, maybe it was decrypted with previous password?
	if [ ! -f "${sourceFullFileName}" ]; then
		log_message "try_password_on_file(): source file not found (or not a file): ${sourceFullFileName}"
		return
	fi # source file exists?

	# check if the sourcefile exists, maybe it was decrypted with previous password?
	if [ -f "${targetFullFileName}" ]; then
		log_message "try_password_on_file(): target file found: ${targetFullFileName}"
		return
	fi # source file exists?

	qpdf --requires-password --password="${thePassword}" "${sourceFullFileName}"
	requirePasswordResult=${?}
	if [ ${requirePasswordResult} -eq 2 ]; then
		# Should not happen, because of previous validations
		log_message "try_password_on_file(): File is NOT encrypted!"
		return
	fi
	if [ ${requirePasswordResult} -eq 1 ]; then
		# Should not happen, because of unused error Code
		log_message "try_password_on_file(): Unused Error Code!"
		return
	fi
	if [ ${requirePasswordResult} -eq 0 ]; then
		log_message "try_password_on_file(): Password Mismatch!"
		return
	fi
	if [ ${requirePasswordResult} -ne 3 ]; then
		# Should not happen, because of previous validations
		log_message "try_password_on_file(): Unknown Error Code! (requirePasswordResult: ${requirePasswordResult})"
		return
	fi # evaluate requirePasswordResult

	# if we reach this point, we can safely say that ${requirePasswordResult} -eq 3, thus:
	log_message "try_password_on_file(): Found password match with file!"

	local teefileName=$( get_logFileName )

	qpdf --decrypt --password="${thePassword}" "${sourceFullFileName}" "${targetFullFileName}" 2>&1 | tee -a "${teefileName}"
	decryptResult=${?}
	if [ ${decryptResult} -ne 0 ]; then
		log_message "try_password_on_file(): Could not decrypt file! (qpdf errCode: ${decryptResult})"
		return
	fi

	# target file was created?
	if [ ! -f "${targetFullFileName}" ]; then
		log_message "try_password_on_file(): Decrypted target file missing! (maybe a subprocess error?)"
		return
	fi # target file was created?

	# should match target's timestamps with source's timestamps
	log_message "try_password_on_file(): Updating target's timestamps..."
	touch -r "${sourceFullFileName}" "${targetFullFileName}"

	# if decrypt successful, remove original (if aplicable)
	if [ "${KEEP_SOURCEFILE}" == "true" ] ; then
		log_message "try_password_on_file(): Moving source file to processed folder..."
		mv -n "${sourceFullFileName}" "${PROCESSED_FOLDER}"
	fi
	if [ "${KEEP_SOURCEFILE}" == "false" ] ; then
		log_message "try_password_on_file(): Removing source file..."
		rm -f "${sourceFullFileName}"
	fi
}

log_message "Iterating source files: ${SOURCE_FOLDER}"
# must be able to iterate on filenames that have spaces on them
originalIFS="${IFS}"
IFS=$'\n'
for individualFile in ${folderContents}; do
	log_message "Working on individualFile: ${individualFile}"

	if [ -d "${SOURCE_FOLDER}/${individualFile}" ]; then
		log_message "Found a directory! Ignoring..."
		continue
	fi
	# individualFile is a File (notFolder)!

	# check if file is encrypted
	qpdf --is-encrypted "${SOURCE_FOLDER}/${individualFile}"
	isEncryptedResult=${?}
	if [ ${isEncryptedResult} -eq 2 ]; then
		log_message "File is NOT encrypted!"
		# if decrypt successful , remove original (if aplicable)
		if [ "${MOVE_UNENCRYPTED}" == "true" ] ; then
			log_message "Moving to target folder..."
			mv "${SOURCE_FOLDER}/${individualFile}" "${TARGET_FOLDER}"
		fi
		continue
	fi

	if [ ${isEncryptedResult} -eq  1 ]; then
		# Should not happen, because of unused error Code
		log_message "Unused Error Code!"
		continue
	fi

	if [ ${isEncryptedResult} -ne 0 ]; then
		# Should not happen, because of unknown error Code
		log_message "Unknown Error Code! (isEncryptedResult: ${isEncryptedResult})"
		continue
	fi # evaluate isEncryptedResult

	# if we reach this point, we can safely say that ${isEncryptedResult} -eq 0, thus:
	log_message "File IS encrypted!"

	log_message "Trying empty password on file..."
	try_password_on_file --emptyPassword -sf "${SOURCE_FOLDER}/${individualFile}" -tf "${TARGET_FOLDER}/${individualFile}"

	log_message "Trying passwords on file..."
	#log_message "DEBUG: passwordList: ${passwordList}"
	for individualPassword in ${passwordList}; do
		# check if the file still exists, maybe it was decrypted with previous password?
		if [ ! -f "${SOURCE_FOLDER}/${individualFile}" ]; then
			continue
		fi # file exists?

		# call try_password_on_file function!
		try_password_on_file -p "${individualPassword}" -sf "${SOURCE_FOLDER}/${individualFile}" -tf "${TARGET_FOLDER}/${individualFile}"
	done
done
# restore originalIFS
IFS="${originalIFS}"
