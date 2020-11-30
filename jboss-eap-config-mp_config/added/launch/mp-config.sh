# Configuration manipulations related to observability of the appserver

if [ -n "${BATS_LOGGING_INCLUDE}" ]; then
    source "${BATS_LOGGING_INCLUDE}"
else
    source $JBOSS_HOME/bin/launch/logging.sh
fi


configure() {
  configure_microprofile_config_source
}

configure_microprofile_config_source() {

  local dirConfigSource=$(generate_microprofile_config_source "${MICROPROFILE_CONFIG_DIR}" "${MICROPROFILE_CONFIG_DIR_ORDINAL}")

  if [ -n "$dirConfigSource" ]; then
    sed -i "s|<!-- ##MICROPROFILE_CONFIG_SOURCE## -->|${dirConfigSource}|" $CONFIG_FILE
  elif [ -n "${MICROPROFILE_CONFIG_DIR}" ]; then
    # Invalid MICROPROFILE_CONFIG_DIR -- was not an absolute path.
    # Since we don't know if the deployment will behave correctly
    # without this config source we shouldn't start.
    log_error "Exiting..."
    exit 1
  fi
  
}

generate_microprofile_config_source() {
  declare dirName="$1" ordinal="$2"

  local dirConfigSource=""

  if [ -n "$dirName" ]; then
    if [[ "$dirName" =~ ^/ ]]; then
      if [ ! -e "$dirName" ]; then
        log_warning "MICROPROFILE_CONFIG_DIR value '$dirName' is a non-existent path. The server may fail readiness and liveness checks and any config values expected to be derived from the Microprofile Config directory ConfigSource will not be applied."
      elif [ ! -d "$dirName" ]; then
        log_warning "MICROPROFILE_CONFIG_DIR value '$dirName' is not a directory. The server may fail readiness and liveness checks and any config values expected to be derived from the Microprofile Config directory ConfigSource will not be applied."
      fi
    else
      log_warning "MICROPROFILE_CONFIG_DIR value '$dirName' is not an absolute path. Use of a relative path is not supported, unpredictable results may occur and behavior may change in future image updates."
    fi
    dirConfigSource="<config-source ordinal=\"${ordinal:-500}\" name=\"config-map\"><dir path=\"$dirName\"/></config-source>"
  fi

  echo $dirConfigSource
}

