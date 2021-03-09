function configure() {
  configure_json_logging
}

function configure_json_logging() {
  sed -i "s|^.*\.module=org\.jboss\.logmanager\.ext$||" $LOGGING_FILE

  if [ "${ENABLE_JSON_LOGGING^^}" == "TRUE" ]; then
    sed -i 's|##CONSOLE-FORMATTER##|OPENSHIFT|' $CONFIG_FILE
  else
    sed -i 's|##CONSOLE-FORMATTER##|COLOR-PATTERN|' $CONFIG_FILE
    configure_pattern_formatter
  fi
}

function configure_pattern_formatter(){
   
    pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"
    if [ "x${LOGGER_PATTERN}" != "x" ]; then
        pattern=${LOGGER_PATTERN}
    fi
    sed -i 's|##PATTERN_FORMATTER##|${PATTERN_FORMATTER}|' $CONFIG_FILE
}