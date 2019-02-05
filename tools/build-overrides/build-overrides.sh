#!/usr/bin/env bash

# Required:
#   awk, bash, date, echo, env, getopts, grep, mkdir, read
#   curl
#   unzip, zipinfo
#   md5sum, sha1sum, sha256sum
#   cekit 2.2.4 or higher (includes cekit-cache)

download() {
    local url=${1}
    local file=${2}
    local code
    if [ ! -f "${file}" ]; then
        echo "Downloading ${url} to ${file} ..."
        curl --silent --location --show-error --fail "${url}" --output "${file}"
        code=$?
    else
        echo "File ${file} already downloaded."
        code=0
    fi
    return ${code}
}

extract() {
    local parent_file=${1}
    local child_name=${2}
    local artifacts_dir=${3}
    local child_file="${artifacts_dir}/${child_name}"
    if [ ! -f "${child_file}" ]; then
        echo "Extracting ${parent_file}!${child_name} to ${child_file} ..."
        unzip "${parent_file}" "${child_name}" -d "${artifacts_dir}"
    else
        echo "File ${child_file} already extracted."
    fi
}

get_zip_path() {
    local zip_file=${1}
    local zip_expr=${2}
    local zip_path=$(zipinfo -1 "${zip_file}" | egrep "${zip_expr}")
    echo -n "${zip_path}"
}

get_url() {
    local key=${1}
    local file=${2}
    local url=$(grep "${key}" "${file}" | awk -F\= '{ print $2 }')
    echo -n ${url}
}

get_name() {
    local url=${1}
    local file_name="$(echo ${url} | awk -F/ '{ print $NF }')"
    echo -n ${file_name}
}

get_sum() {
    local algo=${1}
    local file=${2}
    local checksum=$("${algo}sum" "${file}" | awk '{ print $1 }')
    echo -n ${checksum}
}

cache() {
    local file=${1}
    local name=$(get_name "${file}")
    local cache_ls cache_code
    # below we use grep instead of "cekit-cache ls" because of https://github.com/cekit/cekit/issues/359
    cache_ls=$(grep "${name}" ~/.cekit/cache/*.yaml)
    cache_code=$?
    if [ ${cache_code} = 0 ]; then
        echo "File ${file} already cached."
    else
        echo "Caching ${file} ..."
        local sha256=$(get_sum "sha256" "${file}")
        local sha1=$(get_sum "sha1" "${file}")
        local md5=$(get_sum "md5" "${file}")
        cekit-cache add "${file}" --sha256 "${sha256}" --sha1 "${sha1}" --md5 "${md5}"
    fi
}

handle_rhdm_artifacts() {
    local full_version=${1}
    local short_version=${2}
    local build_type=${3}
    local build_date=${4}
    local artifacts_dir="${5}"
    local overrides_dir="${6}"

    local build_url
    if [ "${build_type}" = "nightly" ]; then
        build_url="http://rcm-guest.app.eng.bos.redhat.com/rcm-guest/staging/rhdm/RHDM-${full_version}.NIGHTLY/rhdm-${build_date}.properties"
    elif [ "${build_type}" = "staging" ]; then
        build_rul="http://rcm-guest.app.eng.bos.redhat.com/rcm-guest/staging/rhdm/RHDM-${full_version}/rhdm-deliverable-list-staging.properties"
    elif [ "${build_type}" = "candidate" ]; then
        build_url="http://download.devel.redhat.com/devel/candidates/RHDM/RHDM-${full_version}/rhdm-deliverable-list.properties"
    else
        # shouldn't happen due to validation in main function
        return 1
    fi
    local build_file=${artifacts_dir}/$(get_name "${build_url}")
    local build_code
    download "${build_url}" "${build_file}"
    build_code=$?
    if [ ${build_code} != 0 ]; then
        (>&2 echo "${build_url} could not be downloaded. Skipping...")
        return 1
    fi

    # ADD_ONS_DISTRIBUTION_ZIP
    local add_ons_distribution_url=$(get_url "rhdm.addons.latest.url" "${build_file}")
    local add_ons_distribution_zip=$(get_name "${add_ons_distribution_url}")
    local add_ons_distribution_file="${artifacts_dir}/${add_ons_distribution_zip}"
    download "${add_ons_distribution_url}" "${add_ons_distribution_file}"
    cache "${add_ons_distribution_file}"
    local add_ons_distribution_md5=$(get_sum "md5" "${add_ons_distribution_file}")

    # CONTROLLER_DISTRIBUTION_ZIP
    local controller_distribution_zip="rhdm-${short_version}-controller-ee7.zip"

    # EMPLOYEE_ROSTERING_DISTRIBUTION_ZIP
    local employee_rostering_distribution_zip="rhdm-${short_version}-employee-rostering.zip"

    # EMPLOYEE_ROSTERING_DISTRIBUTION_WAR
    extract "${add_ons_distribution_file}" "${employee_rostering_distribution_zip}" "${artifacts_dir}"
    local employee_rostering_distribution_file="${artifacts_dir}/${employee_rostering_distribution_zip}"
    local employee_rostering_distribution_war=$(get_zip_path "${employee_rostering_distribution_file}" '.*binaries.*war')

    # DECISION_CENTRAL_DISTRIBUTION_ZIP
    local decision_central_distribution_url=$(get_url "rhdm.decision-central-eap7.latest.url" "${build_file}")
    local decision_central_distribution_zip=$(get_name "${decision_central_distribution_url}")
    local decision_central_distribution_file="${artifacts_dir}/${decision_central_distribution_zip}"
    download "${decision_central_distribution_url}" "${decision_central_distribution_file}"
    cache "${decision_central_distribution_file}"
    local decision_central_distribution_md5=$(get_sum "md5" "${decision_central_distribution_file}")

    # KIE_SERVER_DISTRIBUTION_ZIP
    local kie_server_distribution_url=$(get_url "rhdm.kie-server.ee7.latest.url" "${build_file}")
    local kie_server_distribution_zip=$(get_name "${kie_server_distribution_url}")
    local kie_server_distribution_file="${artifacts_dir}/${kie_server_distribution_zip}"
    download "${kie_server_distribution_url}" "${kie_server_distribution_file}"
    cache "${kie_server_distribution_file}"
    local kie_server_distribution_md5=$(get_sum "md5" "${kie_server_distribution_file}")

    local controller_overrides_file="${overrides_dir}/rhdm-controller-overrides.yaml"
    if [ ! -f "${controller_overrides_file}" ]; then
        echo "Generating ${controller_overrides_file} ..."
cat <<EOF > "${controller_overrides_file}"
envs:
    - name: "CONTROLLER_DISTRIBUTION_ZIP"
      value: "${controller_distribution_zip}"
artifacts:
    - name: ADD_ONS_DISTRIBUTION.ZIP
      path: ${add_ons_distribution_zip}
      md5: ${add_ons_distribution_md5}
EOF
    else
        echo "File ${controller_overrides_file} already generated."
    fi

    local decisioncentral_overrides_file="${overrides_dir}/rhdm-decisioncentral-overrides.yaml"
    if [ ! -f "${decisioncentral_overrides_file}" ]; then
        echo "Generating ${decisioncentral_overrides_file} ..."
cat <<EOF > "${decisioncentral_overrides_file}"
artifacts:
    - name: DECISION_CENTRAL_DISTRIBUTION.ZIP
      path: ${decision_central_distribution_zip}
      md5: ${decision_central_distribution_md5}
EOF
    else
        echo "File ${decisioncentral_overrides_file} already generated."
    fi

    local kieserver_overrides_file="${overrides_dir}/rhdm-kieserver-overrides.yaml"
    if [ ! -f "${kieserver_overrides_file}" ]; then
        echo "Generating ${kieserver_overrides_file} ..."
cat <<EOF > "${kieserver_overrides_file}"
artifacts:
    - name: KIE_SERVER_DISTRIBUTION.ZIP
      path: ${kie_server_distribution_zip}
      md5: ${kie_server_distribution_md5}
EOF
    else
        echo "File ${kieserver_overrides_file} already generated."
    fi

    local optaweb_employee_rostering_overrides_file="${overrides_dir}/rhdm-optaweb-employee-rostering-overrides.yaml"
    if [ ! -f "${optaweb_employee_rostering_overrides_file}" ]; then
        echo "Generating ${optaweb_employee_rostering_overrides_file} ..."
cat <<EOF > "${optaweb_employee_rostering_overrides_file}"
envs:
    - name: "EMPLOYEE_ROSTERING_DISTRIBUTION_ZIP"
      value: "${employee_rostering_distribution_zip}"
    - name: "EMPLOYEE_ROSTERING_DISTRIBUTION_WAR"
      value: "${employee_rostering_distribution_war}"
artifacts:
    - name: ADD_ONS_DISTRIBUTION.ZIP
      path: ${add_ons_distribution_zip}
      md5: ${add_ons_distribution_md5}
EOF
    else
        echo "File ${optaweb_employee_rostering_overrides_file} already generated."
    fi
}

handle_rhpam_artifacts() {
    local full_version=${1}
    local short_version=${2}
    local build_type=${3}
    local build_date=${4}
    local artifacts_dir="${5}"
    local overrides_dir="${6}"

    local build_url
    if [ "${build_type}" = "nightly" ]; then
        build_url="http://rcm-guest.app.eng.bos.redhat.com/rcm-guest/staging/rhpam/RHPAM-${full_version}.NIGHTLY/rhpam-${build_date}.properties"
    elif [ "${build_type}" = "staging" ]; then
        build_rul="http://rcm-guest.app.eng.bos.redhat.com/rcm-guest/staging/rhpam/RHPAM-${full_version}/rhpam-deliverable-list-staging.properties"
    elif [ "${build_type}" = "candidate" ]; then
        build_url="http://download.devel.redhat.com/devel/candidates/RHPAM/RHPAM-${full_version}/rhpam-deliverable-list.properties"
    else
        # shouldn't happen due to validation in main function
        return 1
    fi
    local build_file=${artifacts_dir}/$(get_name "${build_url}")
    local build_code
    download "${build_url}" "${build_file}"
    build_code=$?
    if [ ${build_code} != 0 ]; then
        (>&2 echo "${build_url} could not be downloaded. Skipping...")
        return 1
    fi

    # ADD_ONS_DISTRIBUTION_ZIP
    local add_ons_distribution_url=$(get_url "rhpam.addons.latest.url" "${build_file}")
    local add_ons_distribution_zip=$(get_name "${add_ons_distribution_url}")
    local add_ons_distribution_file="${artifacts_dir}/${add_ons_distribution_zip}"
    download "${add_ons_distribution_url}" "${add_ons_distribution_file}"
    cache "${add_ons_distribution_file}"
    local add_ons_distribution_md5=$(get_sum "md5" "${add_ons_distribution_file}")

    # CONTROLLER_DISTRIBUTION_ZIP
    local controller_distribution_zip="rhpam-${short_version}-controller-ee7.zip"

    # KIE_ROUTER_DISTRIBUTION_JAR
    local kie_router_distribution_jar="rhpam-${short_version}-smart-router.jar"

    # BUSINESS_CENTRAL_DISTRIBUTION_ZIP
    local business_central_distribution_url=$(get_url "rhpam.business-central-eap7.latest.url" "${build_file}")
    local business_central_distribution_zip=$(get_name "${business_central_distribution_url}")
    local business_central_distribution_file="${artifacts_dir}/${business_central_distribution_zip}"
    download "${business_central_distribution_url}" "${business_central_distribution_file}"
    cache "${business_central_distribution_file}"
    local business_central_distribution_md5=$(get_sum "md5" "${business_central_distribution_file}")

    # BUSINESS_CENTRAL_MONITORING_DISTRIBUTION_ZIP
    local business_central_monitoring_distribution_url=$(get_url "rhpam.monitoring.latest.url" "${build_file}")
    if [ -z "${business_central_monitoring_distribution_url}" ]; then
        business_central_monitoring_distribution_url=$(echo "${business_central_distribution_url}" | sed -e 's/business-central-eap7-deployable/monitoring-ee7/')
        echo "Property \"rhpam.monitoring.latest.url\" is not defined. Attempting ${business_central_monitoring_distribution_url} ..."
    fi
    local business_central_monitoring_distribution_zip=$(get_name "${business_central_monitoring_distribution_url}")
    local business_central_monitoring_distribution_file="${artifacts_dir}/${business_central_monitoring_distribution_zip}"
    download "${business_central_monitoring_distribution_url}" "${business_central_monitoring_distribution_file}"
    cache "${business_central_monitoring_distribution_file}"
    local business_central_monitoring_distribution_md5=$(get_sum "md5" "${business_central_monitoring_distribution_file}")

    # KIE_SERVER_DISTRIBUTION_ZIP
    local kie_server_distribution_url=$(get_url "rhpam.kie-server.ee7.latest.url" "${build_file}")
    local kie_server_distribution_zip=$(get_name "${kie_server_distribution_url}")
    local kie_server_distribution_file="${artifacts_dir}/${kie_server_distribution_zip}"
    download "${kie_server_distribution_url}" "${kie_server_distribution_file}"
    cache "${kie_server_distribution_file}"
    local kie_server_distribution_md5=$(get_sum "md5" "${kie_server_distribution_file}")

    # JBPM_WB_KIE_SERVER_BACKEND_JAR
    local jbpm_wb_kie_server_backend_path=$(get_zip_path "${business_central_distribution_file}" '.*jbpm-wb-kie-server-backend.*\.jar')
    local jbpm_wb_kie_server_backend_jar=$(get_name "${jbpm_wb_kie_server_backend_path}")

    local businesscentral_overrides_file="${overrides_dir}/rhpam-businesscentral-overrides.yaml"
    if [ ! -f "${businesscentral_overrides_file}" ]; then
        echo "Generating ${businesscentral_overrides_file} ..."
cat <<EOF > "${businesscentral_overrides_file}"
artifacts:
    - name: BUSINESS_CENTRAL_DISTRIBUTION.ZIP
      path: ${business_central_distribution_zip}
      md5: ${business_central_distribution_md5}
EOF
    else
        echo "File ${businesscentral_overrides_file} already generated."
    fi

    local businesscentral_monitoring_overrides_file="${overrides_dir}/rhpam-businesscentral-monitoring-overrides.yaml"
    if [ ! -f "${businesscentral_monitoring_overrides_file}" ]; then
        echo "Generating ${businesscentral_monitoring_overrides_file} ..."
cat <<EOF > "${businesscentral_monitoring_overrides_file}"
artifacts:
    - name: BUSINESS_CENTRAL_MONITORING_DISTRIBUTION.ZIP
      path: ${business_central_monitoring_distribution_zip}
      md5: ${business_central_monitoring_distribution_md5}
EOF
    else
        echo "File ${businesscentral_monitoring_overrides_file} already generated."
    fi

    local controller_overrides_file="${overrides_dir}/rhpam-controller-overrides.yaml"
    if [ ! -f "${controller_overrides_file}" ]; then
        echo "Generating ${controller_overrides_file} ..."
cat <<EOF > "${controller_overrides_file}"
envs:
    - name: "CONTROLLER_DISTRIBUTION_ZIP"
      value: "${controller_distribution_zip}"
artifacts:
    - name: ADD_ONS_DISTRIBUTION.ZIP
      path: ${add_ons_distribution_zip}
      md5: ${add_ons_distribution_md5}
EOF
    else
        echo "File ${controller_overrides_file} already generated."
    fi

    local kieserver_overrides_file="${overrides_dir}/rhpam-kieserver-overrides.yaml"
    if [ ! -f "${kieserver_overrides_file}" ]; then
        echo "Generating ${kieserver_overrides_file} ..."
cat <<EOF > "${kieserver_overrides_file}"
envs:
    - name: "JBPM_WB_KIE_SERVER_BACKEND_JAR"
      value: "${jbpm_wb_kie_server_backend_jar}"
artifacts:
    - name: KIE_SERVER_DISTRIBUTION.ZIP
      path: ${kie_server_distribution_zip}
      md5: ${kie_server_distribution_md5}
    - name: BUSINESS_CENTRAL_DISTRIBUTION.ZIP
      path: ${business_central_distribution_zip}
      md5: ${business_central_distribution_md5}
EOF
    else
        echo "File ${kieserver_overrides_file} already generated."
    fi

    local smartrouter_overrides_file="${overrides_dir}/rhpam-smartrouter-overrides.yaml"
    if [ ! -f "${smartrouter_overrides_file}" ]; then
        echo "Generating ${smartrouter_overrides_file} ..."
cat <<EOF > "${smartrouter_overrides_file}"
envs:
    - name: "KIE_ROUTER_DISTRIBUTION_JAR"
      value: "${kie_router_distribution_jar}"
artifacts:
    - name: ADD_ONS_DISTRIBUTION.ZIP
      path: ${add_ons_distribution_zip}
      md5: ${add_ons_distribution_md5}
EOF
    else
        echo "File ${smartrouter_overrides_file} already generated."
    fi
}

main() {
    local args
    IFS=' ' read -r -a args <<< "$(echo ${@})"
    local build_tool="build-overrides"
    local full_version
    local build_type
    local build_type_default="nightly"
    local build_date
    local build_date_default=$(date '+%Y%m%d')
    local version_example="7.3.0"
    local default_dir
    local default_dir_example="/tmp/${build_tool}/${build_type_default}/${build_date_default}/${version_example}"
    local artifacts_dir
    local overrides_dir
    local usage_help
    local OPTIND opt
    while getopts ":v:t:b:d:a:o:h:" opt ${args[@]}; do
        case "${opt}" in
            v)      full_version="${OPTARG}"      ;;
            t)        build_type="${OPTARG}"      ;;
            b)        build_date="${OPTARG}"      ;;
            d)       default_dir="${OPTARG}"      ;;
            a)     artifacts_dir="${OPTARG}"      ;;
            o)     overrides_dir="${OPTARG}"      ;;
            h)        usage_help="${OPTARG}"      ;;
           \?) echo "Invalid arg: ${OPTARG}" 1>&2 ;;
        esac
    done
    shift $((OPTIND -1))
    if [ -n "${usage_help}" ] || [[ $(echo ${args[@]}) =~ .*\-h.* ]]; then
        # usage/help
        echo "Usage: ${build_tool}.sh [-v \"#.#.#\"] [-t \"${build_type_default}\"] [-b \"YYYYMMDD\"] [-d \"DEFAULT_DIR\"] [-a \"ARTIFACT_DIR\"] [-o \"OVERRIDES_DIR\"] [-h]"
        echo "-v = [v]ersion (required; format: major.minor.micro; example: ${version_example})"
        echo "-t = [t]ype of build (optional; default: ${build_type_default}; allowed: nightly, staging, candidate)"
        echo "-b = [b]uild date (optional; default: ${build_date_default})"
        echo "-d = [d]efault directory (optional; default example: ${default_dir_example})"
        echo "-a = [a]rtifacts directory (optional; default: default directory)"
        echo "-o = [o]verrides directory (optional; default: default directory)"
        echo "-h = [h]elp / usage"
    elif [ -z "${full_version}" ]; then
        (>&2 echo "Version is required. Run ${build_tool}.sh -h for help.")
    else
        # parse version
        local version_array
        IFS='.' read -r -a version_array <<< "${full_version}"
        local short_version="${version_array[0]}.${version_array[1]}"

        # build type
        if [ -z "${build_type}" ]; then
            build_type="${build_type_default}"
        elif [ "${build_type}" != "nightly" ] && [ "${build_type}" != "staging" ] && [ "${build_type}" != "candidate" ] ; then
            (>&2 echo "Build type not recognized. Must be nightly, staging, or candidate. Run ${build_tool}.sh -h for help.")
            return 1
        fi
        # build date
        if [ -z "${build_date}" ]; then
            build_date="${build_date_default}"
        fi

        # default directory
        if [ -z "${default_dir}" ]; then
            default_dir="/tmp/${build_tool}/${build_type}/${build_date}/${full_version}"
        fi
        # artifacts directory
        if [ -z "${artifacts_dir}" ]; then
            artifacts_dir="${default_dir}"
        fi
        # overrides directory
        if [ -z "${overrides_dir}" ]; then
            overrides_dir="${default_dir}"
        fi
        mkdir -p "${artifacts_dir}"
        mkdir -p "${overrides_dir}"

        # handle artifacts
        handle_rhdm_artifacts "${full_version}" "${short_version}" "${build_type}" "${build_date}" "${artifacts_dir}" "${overrides_dir}"
        handle_rhpam_artifacts "${full_version}" "${short_version}" "${build_type}" "${build_date}" "${artifacts_dir}" "${overrides_dir}"
    fi
}

main $@
