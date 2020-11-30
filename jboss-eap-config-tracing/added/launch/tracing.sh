# only processes a single environment as the placeholder is not preserved

configure() {

  if [ "x${WILDFLY_TRACING_ENABLED}" == "xtrue" ]; then

    local extension="<extension module=\"org.wildfly.extension.microprofile.opentracing-smallrye\"/>"
    local subsystem="<subsystem xmlns=\"urn:wildfly:microprofile-opentracing-smallrye:1.0\"/>"

    sed -i "s|<!-- ##TRACING_EXTENSION## -->|${extension}|" $CONFIG_FILE
    sed -i "s|<!-- ##TRACING_SUBSYSTEM## -->|${subsystem}|" $CONFIG_FILE
  fi
}

