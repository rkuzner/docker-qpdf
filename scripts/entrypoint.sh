#!/bin/bash

# import log_message function
scriptFolder=$( cd "$( dirname "${0}" )" && pwd )
source "${scriptFolder}/log-message.sh"

toolBaseFileName="tool-run"
toolScriptFileName="${toolBaseFileName}.sh"
toolConfigFileName="${toolBaseFileName}.conf"
userName="theuser"
userHomeFolder="home/${userName}"

DEFAULT_LOG_FOLDER="/logs"
DEFAULT_SOURCE_FOLDER="/source"
DEFAULT_TARGET_FOLDER="/target"
DEFAULT_KEEP_SOURCEFILE="false"
DEFAULT_MOVE_UNENCRYPTED="true"

set_logFolder "${LOG_FOLDER:-${DEFAULT_LOG_FOLDER}}"

log_message "-+*+- -+*+- -+*+- -+*+- -+*+-"
log_message "-+*+-  Container START  -+*+-"
log_message "-+*+- -+*+- -+*+- -+*+- -+*+-"

log_message "Preparing user: ${userName}..."

PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" ${userName}
usermod -o -u "$PUID" ${userName}

log_message "Evaluating environment variables..."
if [ -n "${TOOL_NAME}" ]; then
  log_message "Found TOOL_NAME environment var!"
fi

# evaluate if SOURCE_FOLDER is valid, if not use default
SOURCE_FOLDER="${SOURCE_FOLDER:-${DEFAULT_SOURCE_FOLDER}}"
if [ ! -d "${SOURCE_FOLDER}" ]; then
  log_message "Invalid SOURCE_FOLDER: ${SOURCE_FOLDER}"
  SOURCE_FOLDER="${DEFAULT_SOURCE_FOLDER}"
fi
log_message "Using SOURCE_FOLDER: ${SOURCE_FOLDER}"

# evaluate if TARGET_FOLDER is valid, if not use default
TARGET_FOLDER="${TARGET_FOLDER:-${DEFAULT_TARGET_FOLDER}}"
if [ ! -d "${TARGET_FOLDER}" ]; then
  log_message "Invalid TARGET_FOLDER: ${TARGET_FOLDER}"
  TARGET_FOLDER="${DEFAULT_TARGET_FOLDER}"
fi
log_message "Using TARGET_FOLDER: ${TARGET_FOLDER}"

# evaluate if KEEP_SOURCEFILE is valid, if not use default
KEEP_SOURCEFILE="${KEEP_SOURCEFILE:-${DEFAULT_KEEP_SOURCEFILE}}"
if [ "${KEEP_SOURCEFILE}" != "false" ] && [ "${KEEP_SOURCEFILE}" != "true" ]; then
  log_message "Invalid KEEP_SOURCEFILE: ${KEEP_SOURCEFILE}"
  KEEP_SOURCEFILE="${DEFAULT_KEEP_SOURCEFILE}"
fi
log_message "Using KEEP_SOURCEFILE: ${KEEP_SOURCEFILE}"

# evaluate if MOVE_UNENCRYPTED is valid, if not use default
MOVE_UNENCRYPTED="${MOVE_UNENCRYPTED:-${DEFAULT_MOVE_UNENCRYPTED}}"
if [ "${MOVE_UNENCRYPTED}" != "false" ] && [ "${MOVE_UNENCRYPTED}" != "true" ]; then
  log_message "Invalid MOVE_UNENCRYPTED: ${MOVE_UNENCRYPTED}"
  MOVE_UNENCRYPTED="${DEFAULT_MOVE_UNENCRYPTED}"
fi
log_message "Using MOVE_UNENCRYPTED: ${MOVE_UNENCRYPTED}"
log_message "Done evaluating environment variables."

log_message "Preparing ${toolConfigFileName} file..."
touch /${userHomeFolder}/${toolConfigFileName}

# evaluate if TOOL_NAME was set on ENV, if so, append to conf file
if [ -n "${TOOL_NAME}" ]; then
  log_message "Append TOOL_NAME info to ${toolConfigFileName} file"
  echo 'TOOL_NAME="'${TOOL_NAME}'"' >> /${userHomeFolder}/${toolConfigFileName}
fi

log_message "Append SOURCE_FOLDER info to ${toolConfigFileName} file"
echo 'SOURCE_FOLDER="'${SOURCE_FOLDER}'"' >> /${userHomeFolder}/${toolConfigFileName}

log_message "Append TARGET_FOLDER info to ${toolConfigFileName} file"
echo 'TARGET_FOLDER="'${TARGET_FOLDER}'"' >> /${userHomeFolder}/${toolConfigFileName}

log_message "Append KEEP_SOURCEFILE to ${toolConfigFileName} file"
echo 'KEEP_SOURCEFILE="'${KEEP_SOURCEFILE}'"' >> /${userHomeFolder}/${toolConfigFileName}

log_message "Append MOVE_UNENCRYPTED to ${toolConfigFileName} file"
echo 'MOVE_UNENCRYPTED="'${MOVE_UNENCRYPTED}'"' >> /${userHomeFolder}/${toolConfigFileName}

log_message "Append PASSWORDS_FILENAME info to ${toolConfigFileName} file"
echo 'PASSWORDS_FILENAME="'${PASSWORDS_FILENAME}'"' >> /${userHomeFolder}/${toolConfigFileName}

chown ${userName}:${userName} /${userHomeFolder}/${toolConfigFileName}
log_message "Done preparing ${toolConfigFileName} file."

# check if TOOL_SCHEDULE was set on ENV. if so, set crontab schedule with it
if [ -n "${TOOL_SCHEDULE}" ]; then
  log_message "Found TOOL_SCHEDULE environment var!"

  log_message "Clear crontab schedule"
  crontab -u ${userName} -r 2>/dev/null
  exitCode=${?}
  if [ ${exitCode} -gt 0 ] ; then
    log_message "There was a problem clearing crontab schedule, exitCode was: ${exitCode}"
  fi

  log_message "Set crontab schedule"
  echo "${TOOL_SCHEDULE} /${userHomeFolder}/${toolScriptFileName}" | crontab -u ${userName} -
  exitCode=${?}
  if [ ${exitCode} -gt 0 ] ; then
    log_message "There was a problem setting crontab schedule, exitCode was: ${exitCode}"
  fi

  log_message "Restart cron service"
  service cron restart
  exitCode=${?}
  if [ ${exitCode} -gt 0 ] ; then
    log_message "There was a problem restarting cron service, exitCode was: ${exitCode}"
  fi
else
  log_message "No TOOL_SCHEDULE environment var Found!"
  log_message "This is a Single run!"
  exec sudo -u ${userName} /${userHomeFolder}/${toolScriptFileName}
  exit ${?}
fi

# keep the image running...
/bin/bash
