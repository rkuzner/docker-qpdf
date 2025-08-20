#!/bin/bash

# import log_message function
scriptFolder=$( cd "$( dirname "${0}" )" && pwd )
source "${scriptFolder}/log-message.sh"

DEFAULT_LOG_FOLDER="/logs"
DEFAULT_SOURCE_FOLDER="/source"
DEFAULT_TARGET_FOLDER="/target"
DEFAULT_KEEP_SOURCEFILE="false"
DEFAULT_MOVE_UNENCRYPTED="true"

if [ -z "${LOG_FOLDER}" ]; then
	LOG_FOLDER="${DEFAULT_LOG_FOLDER}"
fi
set_logFolder ${LOG_FOLDER}

log_message " -+*+- -+*+- -+*+- -+*+- "
log_message "Preparing tool-run.conf file..."
echo "#!/bin/bash" > /home/theuser/tool-run.conf

# evaluate if TOOL_NAME was set on ENV, if so, append to conf file
if [ -n "${TOOL_NAME}" ]; then
  log_message "Found TOOL_NAME environment var!"
  log_message "Append TOOL_NAME info to tool-run.conf file"
  echo 'TOOL_NAME="'${TOOL_NAME}'"' >> /home/theuser/tool-run.conf
fi

# evaluate if SOURCE_FOLDER was set on ENV, if so, only use if valid
if [ -n "${SOURCE_FOLDER}" ]; then
  log_message "Found SOURCE_FOLDER environment var!"
  if [ -d "${SOURCE_FOLDER}" ]; then
    log_message "Valid SOURCE_FOLDER environment var: ${SOURCE_FOLDER}"
    DEFAULT_SOURCE_FOLDER="${SOURCE_FOLDER}"
  fi
fi
log_message "Using SOURCE_FOLDER: ${DEFAULT_SOURCE_FOLDER}"
log_message "Append SOURCE_FOLDER info to tool-run.conf file"
echo 'SOURCE_FOLDER="'${SOURCE_FOLDER}'"' >> /home/theuser/tool-run.conf

# evaluate if TARGET_FOLDER was set on ENV, if so, only use if valid
if [ -n "${TARGET_FOLDER}" ]; then
  log_message "Found TARGET_FOLDER environment var!"
  if [ -d "${TARGET_FOLDER}" ]; then
    log_message "Valid TARGET_FOLDER environment var: ${TARGET_FOLDER}"
    DEFAULT_TARGET_FOLDER="${TARGET_FOLDER}"
  fi
fi
log_message "Using TARGET_FOLDER: ${DEFAULT_TARGET_FOLDER}"
log_message "Append TARGET_FOLDER info to tool-run.conf file"
echo 'TARGET_FOLDER="'${TARGET_FOLDER}'"' >> /home/theuser/tool-run.conf

# evaluate if KEEP_SOURCEFILE was set on ENV, if so, only use if valid
if [ -n "${KEEP_SOURCEFILE}" ]; then
  log_message "Found KEEP_SOURCEFILE environment var!"
  if [ "${KEEP_SOURCEFILE}" = "false" ] || [ "${KEEP_SOURCEFILE}" = "true" ]; then
    DEFAULT_KEEP_SOURCEFILE="${KEEP_SOURCEFILE}"
    log_message "Valid KEEP_SOURCEFILE environment var: ${KEEP_SOURCEFILE}"
  fi
fi
log_message "Using KEEP_SOURCEFILE: ${DEFAULT_KEEP_SOURCEFILE}"
log_message "Append KEEP_SOURCEFILE to tool-run.conf file"
echo 'KEEP_SOURCEFILE="'${DEFAULT_KEEP_SOURCEFILE}'"' >> /home/theuser/tool-run.conf

# evaluate if KEEP_SOURCEFILE was set on ENV, if so, only use if valid
if [ -n "${MOVE_UNENCRYPTED}" ]; then
  log_message "Found MOVE_UNENCRYPTED environment var!"
  if [ "${MOVE_UNENCRYPTED}" = "false" ] || [ "${MOVE_UNENCRYPTED}" = "true" ]; then
    DEFAULT_MOVE_UNENCRYPTED="${MOVE_UNENCRYPTED}"
    log_message "Valid MOVE_UNENCRYPTED environment var: ${MOVE_UNENCRYPTED}"
  fi
fi
log_message "Using MOVE_UNENCRYPTED: ${DEFAULT_MOVE_UNENCRYPTED}"
log_message "Append MOVE_UNENCRYPTED to tool-run.conf file"
echo 'MOVE_UNENCRYPTED="'${DEFAULT_MOVE_UNENCRYPTED}'"' >> /home/theuser/tool-run.conf

log_message "Append PASSWORDS_FILENAME info to tool-run.conf file"
echo 'PASSWORDS_FILENAME="'${PASSWORDS_FILENAME}'"' >> /home/theuser/tool-run.conf

log_message "Done preparing tool-run.conf file."

# check if TOOL_SCHEDULE was set on ENV. if so, set crontab schedule with it
if [ -n "${TOOL_SCHEDULE}" ]; then
  log_message "Found TOOL_SCHEDULE environment var!"

  log_message "Clear crontab schedule"
  crontab -u theuser -r 2>/dev/null | tee -a "${logFile}"

  log_message "Set crontab schedule"
  echo "${TOOL_SCHEDULE} /home/theuser/tool-run.sh" | crontab -u theuser -

  log_message "restart cron service"
  service cron restart
  exitCode=${?}
  if [ ${exitCode} -gt 0 ] ; then
    log_message "There was a problem restarting cron service, exitCode was: ${exitCode}"
  fi
else
  log_message "No TOOL_SCHEDULE environment var Found!"
  log_message "This is a Single run!"
  exec /home/theuser/tool-run.sh
  exit ${?}
fi

# keep the image running...
/bin/bash
