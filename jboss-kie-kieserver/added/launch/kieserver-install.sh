#!/bin/sh
# if using vim, do ':set ft=zsh' for easier reading
source $JBOSS_HOME/bin/launch/logging.sh

LOCAL_SOURCE_DIR=/tmp/src

# By this point, EAP deployments dir will contain everything outputted from s2i, including
# maven-built artifacts in ~/target/, or artifacts copied from ~/source/deployments/.
DEPLOY_DIR="${JBOSS_HOME}/standalone/deployments"

# Ensure that the local maven repository exists
MAVEN_REPO=${HOME}/.m2/repository
mkdir -p ${MAVEN_REPO}

# $1 - file
# $2 - pom file
# $3 - packaging
# $4 - classifier=sources used when a jar is source.
prepare_maven_command() {
    # Add JVM default options
    export MAVEN_OPTS="${MAVEN_OPTS:-$(/opt/run-java/java-default-options)}"
    # Use maven batch mode (CLOUD-579)
    local maven_args_intall="-e -DskipTests install:install-file -Dfile=${1} -DpomFile=${2} -Dpackaging=${3} ${4} --batch-mode -Djava.net.preferIPv4Stack=true -Popenshift -Dcom.redhat.xpaas.repo.redhatga ${MAVEN_ARGS_APPEND}"
    log_info "Attempting to install jar with 'mvn ${maven_args_intall}'"
    log_info "Using MAVEN_OPTS '${MAVEN_OPTS}'"
    log_info "Using $(mvn --version)"
    echo ${maven_args_intall}
}

# $1 - DEPLOY_DIR
# $2 - TEMP_JARS_DIR
# $3 - JAR
# $4 - POM
install_jar_pom() {
    local deploy_dir="${1}"
    local temp_jars_dir="${2}"
    local jar="${3}"
    local pom="${4}"

    # explode if it is a directory
    if [ -d ${deploy_dir}/${jar} ]; then
        # jar is an exploded directory; replace with zipped file (for mvn install:install-file below to work)
        zip -r ${deploy_dir}/${jar}.zip ${deploy_dir}/${jar}/*
        rm -rf ${deploy_dir}/${jar}
        mv ${deploy_dir}/${jar}.zip ${deploy_dir}/${jar}
    fi

    # handle artifacts made with maven-assembly-plugin
    local full_maven_command
    local pom_artifact=$(echo ${pom} | sed 's|/pom\.xml$||' | sed 's@.*/@@')
    if [[ ${jar} =~ ^${pom_artifact}-[0-9].*\.jar ]]; then
        # the jar matches the pom - intall them together
        local classifier=""
        if [[ "${jar}" == *"sources"* ]]; then
            classifier="-Dclassifier=sources"
        fi
        full_maven_command=$(prepare_maven_command "${deploy_dir}/${jar}" "${pom}" "jar" "${classifier}")
    else
        # the jar does not match the pom - intall only the pom
        # TODO: Do we really want to do this?
        full_maven_command=$(prepare_maven_command "${pom}" "${pom}" "pom")
    fi
    if [ -n "${full_maven_command}" ]; then
        mvn ${full_maven_command}
        ERR=$?
        if [ $ERR -ne 0 ]; then
            log_error "Aborting due to error code $ERR from Maven build"
            # cleanup
            rm -rf ${temp_jars_dir}
            exit $ERR
        fi
    fi

    # Discover KIE_SERVER_CONTAINER_DEPLOYMENT for when env var not specified, only kjar (has kmodule.xml) should be configured.
    # verify if the current jar is a kjar
    if [ -e "${temp_jars_dir}/${jar}/META-INF/kmodule.xml" ]; then
        log_info "${deploy_dir}/${jar} is a kmodule: Inspecting kjar ${deploy_dir}/${jar} for artifact information..."
        pushd $(dirname ${pom}) &> /dev/null
            # Add JVM default options
            export MAVEN_OPTS="${MAVEN_OPTS:-$(/opt/run-java/java-default-options)}"
            # Use maven batch mode (CLOUD-579)
            local maven_args_evaluate="--batch-mode -Djava.net.preferIPv4Stack=true -Popenshift -Dcom.redhat.xpaas.repo.redhatga ${MAVEN_ARGS_APPEND}"
            # Trigger download of help:evaluate dependencies
            mvn help:evaluate -Dexpression=project.artifact ${maven_args_evaluate}
            ERR=$?
            if [ $ERR -ne 0 ]; then
                log_error "Aborting due to error code $ERR from Maven artifact discovery"
                exit $ERR
            fi
            # next use help:evaluate to record the kjar as a kie server container deployment
            local kieServerContainerDeploymentsFile="${JBOSS_HOME}/kieserver-container-deployments.txt"
            local kjarGroupId="$(mvn help:evaluate -Dexpression=project.artifact.groupId ${maven_args_evaluate} | egrep -v '(^\[.*\])|(Download.*: )')"
            local kjarArtifactId="$(mvn help:evaluate -Dexpression=project.artifact.artifactId ${maven_args_evaluate} | egrep -v '(^\[.*\])|(Download.*: )')"
            local kjarVersion="$(mvn help:evaluate -Dexpression=project.artifact.version ${maven_args_evaluate} | egrep -v '(^\[.*\])|(Download.*: )')"
            local kieServerContainerDeployment="${kjarArtifactId}=${kjarGroupId}:${kjarArtifactId}:${kjarVersion}"
            log_info "Adding ${kieServerContainerDeployment} to ${kieServerContainerDeploymentsFile}"
            echo "${kieServerContainerDeployment}" >> ${kieServerContainerDeploymentsFile}
            chmod --quiet a+rw ${kieServerContainerDeploymentsFile}
        popd &> /dev/null
    fi
}

if [ -d ${DEPLOY_DIR} ]; then
    log_info "Verifying if the provided maven project is multi-module"
    if [ -f "${LOCAL_SOURCE_DIR}/pom.xml" ]; then
        grep -qE '<module>.*</module>' "${LOCAL_SOURCE_DIR}/pom.xml"
        if [ "$?" == "0" ]; then
            modules=$(grep -E '<module>.*</module>' ${LOCAL_SOURCE_DIR}/pom.xml | awk -F '[<>]' '/module/{print $3}' | tr '\n' ' ')
            log_info "Multi module detected, the modules are: ${modules}"
            mvn $(prepare_maven_command ${LOCAL_SOURCE_DIR}/pom.xml ${LOCAL_SOURCE_DIR}/pom.xml "pom")
            ERR=$?
            if [ $ERR -ne 0 ]; then
                log_error "Aborting due to error code $ERR from Maven build"
                # cleanup
                rm -rf ${TEMP_JARS_DIR}
                exit $ERR
            fi
        fi
    fi

    TEMP_JARS_DIR="${LOCAL_SOURCE_DIR}/tmp-jars"
    # install all jars in the local maven repository, including kjars (has both kmodule.xml and pom.xml)
    for JAR in $(find ${DEPLOY_DIR}/ -maxdepth 1 -name *.jar | sed 's|.*/||'); do
        mkdir -p ${TEMP_JARS_DIR}/${JAR}
        if [ -d ${DEPLOY_DIR}/${JAR} ]; then
            # jar is an exploded directory; copy contents
            cp -r ${DEPLOY_DIR}/${JAR}/* ${TEMP_JARS_DIR}/${JAR}/
        else
            # jar is a zipped file; unzip contents
            unzip -q ${DEPLOY_DIR}/${JAR} -d ${TEMP_JARS_DIR}/${JAR}
        fi

        # at this moment install all jars on local maven repository
        POMS=( $(find ${TEMP_JARS_DIR}/${JAR}/META-INF/maven -name 'pom.xml' 2>/dev/null) )
        for POM in ${POMS[@]}; do
            if [ -e "${POM}" ]; then
                log_info "${DEPLOY_DIR}/${JAR} has a pom: Attempting to install..."
                install_jar_pom "${DEPLOY_DIR}" "${TEMP_JARS_DIR}" "${JAR}" "${POM}"
            fi
        done

        # Remove kjar from EAP deployments dir, as KIE loads them from ${HOME}/.m2/repository/ instead.
        # Leaving this file here could cause classloading collisions if multiple KIE Server Containers
        # are configured for different versions of the same application.
        rm -f ${DEPLOY_DIR}/${JAR}
    done
    # cleanup
    rm -rf ${TEMP_JARS_DIR}

    # Necessary to permit running with a randomised UID
    chown -R --quiet jboss:root ${MAVEN_REPO}
    chmod -R --quiet g+rwX ${MAVEN_REPO}
fi

exit 0
