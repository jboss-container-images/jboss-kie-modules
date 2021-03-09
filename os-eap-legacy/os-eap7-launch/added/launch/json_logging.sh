function configure() {
  configure_json_logging
}

function configure_json_logging() {
  sed -i "s|^.*\.module=org\.jboss\.logmanager\.ext$||" $LOGGING_FILE

  if [ "${ENABLE_JSON_LOGGING^^}" == "TRUE" ]; then
    sed -i 's|##CONSOLE-FORMATTER##|OPENSHIFT|' $CONFIG_FILE
  else
    sed -i 's|##CONSOLE-FORMATTER##|COLOR-PATTERN|' $CONFIG_FILE
  fi
}

function configure_pattern_formatter(){
   
    local enablePatternFormatter="${ENABLE_PATTERN_FORMATTER}"
    local pattern="${PATTERN_FORMATTER}"
    
    if [ "${enablePatternFormatter^^}" == "TRUE" ]; then
        PATTERN_FORMATTER="${pattern}"
    fi
}