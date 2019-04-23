#!/usr/bin/env bash

# Required:
#   awk, bash, date, echo, env, getopts, grep, mkdir, read, realpath
#   curl
#   unzip, zipinfo
#   md5sum, sha1sum, sha256sum
#   cekit 2.2.4 or higher (includes cekit-cache)

log_help() {
    # color: none
    echo 1>&2 -e "${1}"
}

log_debug() {
    # color: blue
    echo 1>&2 -e "\033[0;34m${1}\033[0m"
}

log_info() {
    # color: green
    echo 1>&2 -e "\033[0;32m${1}\033[0m"
}

log_warning() {
    # color: yellow
    echo 1>&2 -e "\033[0;33m${1}\033[0m"
}

log_error() {
    # color: red
    echo 1>&2 -e "\033[0;31m${1}\033[0m"
}

download() {
    local url=${1}
    local file=${2}
    local code
    if [ ! -f "${file}" ]; then
        log_info "Downloading ${url} to ${file} ..."
        curl --silent --location --show-error --fail "${url}" --output "${file}"
        code=$?
        if [ ${code} != 0 ] || [ ! -f "${file}" ]; then
            log_error "Downloading to ${file} failed."
            if [ ${code} = 0 ]; then
                code=1
            fi
        fi
    else
        log_info "File ${file} already downloaded."
        code=0
    fi
    return ${code}
}

extract() {
    local parent_file=${1}
    local child_name=${2}
    local artifacts_dir=${3}
    local child_file="${artifacts_dir}/${child_name}"
    local code
    if [ ! -f "${child_file}" ]; then
        log_info "Extracting ${parent_file}!${child_name} to ${child_file} ..."
        unzip "${parent_file}" "${child_name}" -d "${artifacts_dir}"
        code=$?
        if [ ${code} != 0 ] || [ ! -f "${child_file}" ]; then
            log_error "Extracting to ${child_file} failed."
            if [ ${code} = 0 ]; then
                code=1
            fi
        fi
    else
        log_info "File ${child_file} already extracted."
        code=0
    fi
    return ${code}
}

get_zip_path() {
    local zip_file=${1}
    local zip_expr=${2}
    local zip_path=$(zipinfo -1 "${zip_file}" | egrep "${zip_expr}")
    echo -n "${zip_path}"
}

get_artifact_url() {
    local key=${1}
    local file=${2}
    local url=$(grep "${key}" "${file}" | awk -F\= '{ print $2 }')
    echo -n ${url}
}

get_artifact_name() {
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
    local work_dir=${2}
    local name=$(get_artifact_name "${file}")
    local md5=$(get_sum "md5" "${file}")
    local grep_yaml
    local code=1
    local workdir_opt

    # If work_dir is null, don't set the option on cekit-cache
    # and keep the default of ~/.cekit for the search
    if [ -n "${work_dir}" ]; then
        workdir_opt="--work-dir=${work_dir}"
    else
	work_dir="~/.cekit"
    fi

    for Y in $(grep -ln "${name}" "${workdir}"/cache/*.yaml) ; do
        grep_yaml=$(grep "md5: ${md5}" "${Y}")
        code=$?
        if [ ${code} = 0 ] ; then
            log_info "File ${file} already cached."
            log_debug "Cache entry: ${Y}"
            break
        fi
    done
    if [ ${code} != 0 ] ; then
        log_info "Caching ${file} ..."
        local sha256=$(get_sum "sha256" "${file}")
        local sha1=$(get_sum "sha1" "${file}")
        cekit-cache "${workdir_opt}" add "${file}" --sha256 "${sha256}" --sha1 "${sha1}" --md5 "${md5}"
        code=$?
        if [ ${code} != 0 ]; then
            log_error "Caching of ${file} failed."
        fi
    fi
    return ${code}
}

get_cache_item() {
    local cache_item_source="${1}"
    local artifacts_dir="${2}"
    local cache_item_target=$(get_artifact_name "${cache_item_source}")
    cache_item_target="${artifacts_dir}/${cache_item_target}"
    if [[ "${cache_item_source}" =~ https?://.* ]]; then
        if ! download "${cache_item_source}" "${cache_item_target}" ; then
            return 1
        fi
    else
        if [ -f "${cache_item_source}" ]; then
            local real_cache_item_source=$(realpath "${cache_item_source}")
            local real_cache_item_target=$(realpath "${cache_item_target}")
            if [ "${real_cache_item_source}" = "${real_cache_item_target}" ]; then
                log_warning "File ${cache_item_source} and ${cache_item_target} are the same file."
            else
                if [ -f "${cache_item_target}" ]; then
                    log_warning "File ${cache_item_target} already exists; overwriting ..."
                fi
                log_info "Copying ${cache_item_source} to ${cache_item_target} ..."
                if ! cp -f "${cache_item_source}" "${cache_item_target}" ; then
                    log_error "Copying to ${cache_item_target} failed."
                    return 1
                fi
            fi
        else
            log_warning "File ${cache_item_source} does not exist; skipping ..."
            return 1
        fi
    fi
    echo -n "${cache_item_target}"
}

handle_cache_artifact() {
    local cache_artifact_source="${1}"
    local artifacts_dir="${2}"
    local work_dir="${3}"
    local cache_artifact_target
    cache_artifact_target=$(get_cache_item "${cache_artifact_source}" "${artifacts_dir}")
    if [ $? = 0 ]; then
        cache "${cache_artifact_target}" "${work_dir}"
    fi
}

handle_cache_list() {
    local cache_list_source="${1}"
    local artifacts_dir="${2}"
    local work_dir="${3}"
    local cache_list_target
    cache_list_target=$(get_cache_item "${cache_list_source}" "${artifacts_dir}")
    if [ $? = 0 ]; then
        while IFS= read -r cache_artifact_source ; do
            cache_artifact_source=$(echo "${cache_artifact_source}" | awk '{gsub(/^ +| +$/,"")} { print $0 }')
            if [ -n "${cache_artifact_source}" ]; then
                if [[ "${cache_artifact_source}" =~ \#.* ]]; then
                    log_debug "Ignoring comment line: ${cache_artifact_source}"
                else
                    handle_cache_artifact "${cache_artifact_source}" "${artifacts_dir}" "${work_dir}"
                fi
            fi
        done <"${cache_list_target}"
    fi
}

# http://download.eng.bos.redhat.com/rcm-guest/staging/rhdm/
# http://download.eng.bos.redhat.com/rcm-guest/staging/rhpam/
# http://download.devel.redhat.com/devel/candidates/RHDM/
# http://download.devel.redhat.com/devel/candidates/RHPAM/
get_build_url() {
    local full_version=${1}
    local build_type=${2}
    local build_date=${3}
    local product_suite_lower=${4,,}
    local product_suite_upper=${4^^}
    local build_url
    if [ "${product_suite_lower}" = "rhdm" ] || [ "${product_suite_lower}" = "rhpam" ]; then
        if [ "${build_type}" = "nightly" ]; then
            build_url="http://download.eng.bos.redhat.com/rcm-guest/staging/${product_suite_lower}/${product_suite_upper}-${full_version}.NIGHTLY/${product_suite_lower}-${build_date}.properties"
        elif [ "${build_type}" = "staging" ]; then
            build_url="http://download.eng.bos.redhat.com/rcm-guest/staging/${product_suite_lower}/${product_suite_upper}-${full_version}/${product_suite_lower}-deliverable-list-staging.properties"
        elif [ "${build_type}" = "candidate" ]; then
            build_url="http://download.devel.redhat.com/devel/candidates/${product_suite_upper}/${product_suite_upper}-${full_version}/${product_suite_lower}-deliverable-list.properties"
        fi
    fi
    echo -n "${build_url}"
}

get_build_file() {
    local full_version=${1}
    local build_type=${2}
    local build_date=${3}
    local product_suite=${4}
    local artifacts_dir="${5}"

    local build_url=$(get_build_url "${full_version}" "${build_type}" "${build_date}" "${product_suite}")
    if [ -n "${build_url}" ]; then
        local build_file=${artifacts_dir}/$(get_artifact_name "${build_url}")
        if download "${build_url}" "${build_file}" ; then
            echo -n "${build_file}"
        else
            return 1
        fi
    fi
}

product_matches() {
    local product=${1}
    local suite=${2}
    local component=${3}
    if [ "${product}" = "all" ] || [ "${product}" = "${suite}" ] || [ "${product}" = "${suite}-${component}" ]; then
        return 0
    else
        return 1
    fi
}

handle_rhdm_artifacts() {
    local full_version=${1}
    local short_version=${2}
    local build_type=${3}
    local build_date=${4}
    local product=${5}
    local artifacts_dir="${6}"
    local overrides_dir="${7}"
    local work_dir="${8}"

    local build_file=$(get_build_file "${full_version}" "${build_type}" "${build_date}" "rhdm" "${artifacts_dir}")
    if [ -z "${build_file}" ]; then
        return 1
    fi

    # RHDM Add-Ons
    local add_ons_distribution_zip
    local add_ons_distribution_md5
    if product_matches "${product}" "rhdm" "controller" || product_matches "${product}" "rhdm" "optaweb-employee-rostering" ; then
        local add_ons_distribution_url=$(get_artifact_url "rhdm.addons.latest.url" "${build_file}")
        add_ons_distribution_zip=$(get_artifact_name "${add_ons_distribution_url}")
        local add_ons_distribution_file="${artifacts_dir}/${add_ons_distribution_zip}"
        if download "${add_ons_distribution_url}" "${add_ons_distribution_file}" ; then
            if cache "${add_ons_distribution_file}" "${work_dir}"; then
                add_ons_distribution_md5=$(get_sum "md5" "${add_ons_distribution_file}")
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHDM Controller
    if product_matches "${product}" "rhdm" "controller" ; then
        local controller_distribution_zip="rhdm-${short_version}-controller-ee7.zip"
        local controller_overrides_file="${overrides_dir}/rhdm-controller-overrides.yaml"
        if [ ! -f "${controller_overrides_file}" ]; then
            log_info "Generating ${controller_overrides_file} ..."
cat <<EOF > "${controller_overrides_file}"
envs:
    - name: "CONTROLLER_DISTRIBUTION_ZIP"
      value: "${controller_distribution_zip}"
artifacts:
    - name: "ADD_ONS_DISTRIBUTION_ZIP"
      target: "add_ons_distribution.zip"
      #     ${add_ons_distribution_zip}
      md5: "${add_ons_distribution_md5}"
EOF
        else
            log_info "File ${controller_overrides_file} already generated."
        fi
    fi

    # RHDM Decision Central
    if product_matches "${product}" "rhdm" "decisioncentral" ; then
        local decision_central_distribution_url=$(get_artifact_url "rhdm.decision-central-eap7.latest.url" "${build_file}")
        local decision_central_distribution_zip=$(get_artifact_name "${decision_central_distribution_url}")
        local decision_central_distribution_file="${artifacts_dir}/${decision_central_distribution_zip}"
        if download "${decision_central_distribution_url}" "${decision_central_distribution_file}" ; then
            if cache "${decision_central_distribution_file}" "${work_dir}"; then
                local decision_central_distribution_md5=$(get_sum "md5" "${decision_central_distribution_file}")
                local decisioncentral_overrides_file="${overrides_dir}/rhdm-decisioncentral-overrides.yaml"
                if [ ! -f "${decisioncentral_overrides_file}" ]; then
                    log_info "Generating ${decisioncentral_overrides_file} ..."
cat <<EOF > "${decisioncentral_overrides_file}"
artifacts:
    - name: "DECISION_CENTRAL_DISTRIBUTION_ZIP"
      target: "decision_central_distribution.zip"
      #     ${decision_central_distribution_zip}
      md5: "${decision_central_distribution_md5}"
EOF
                else
                    log_info "File ${decisioncentral_overrides_file} already generated."
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHDM KIE Server
    if product_matches "${product}" "rhdm" "kieserver" ; then
        local kie_server_distribution_url=$(get_artifact_url "rhdm.kie-server.ee8.latest.url" "${build_file}")
        local kie_server_distribution_zip=$(get_artifact_name "${kie_server_distribution_url}")
        local kie_server_distribution_file="${artifacts_dir}/${kie_server_distribution_zip}"
        if download "${kie_server_distribution_url}" "${kie_server_distribution_file}" ; then
            if cache "${kie_server_distribution_file}" "${work_dir}"; then
                local kie_server_distribution_md5=$(get_sum "md5" "${kie_server_distribution_file}")
                local kieserver_overrides_file="${overrides_dir}/rhdm-kieserver-overrides.yaml"
                if [ ! -f "${kieserver_overrides_file}" ]; then
                    log_info "Generating ${kieserver_overrides_file} ..."
cat <<EOF > "${kieserver_overrides_file}"
artifacts:
    - name: "KIE_SERVER_DISTRIBUTION_ZIP"
      target: "kie_server_distribution.zip"
      #     ${kie_server_distribution_zip}
      md5: "${kie_server_distribution_md5}"
EOF
                else
                    log_info "File ${kieserver_overrides_file} already generated."
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHDM Optaweb Employee Rostering
    if product_matches "${product}" "rhdm" "optaweb-employee-rostering" ; then
        local employee_rostering_distribution_zip="rhdm-${short_version}-employee-rostering.zip"
        if extract "${add_ons_distribution_file}" "${employee_rostering_distribution_zip}" "${artifacts_dir}" ; then
            local employee_rostering_distribution_file="${artifacts_dir}/${employee_rostering_distribution_zip}"
            local employee_rostering_distribution_war=$(get_zip_path "${employee_rostering_distribution_file}" '.*binaries.*war')
            local optaweb_employee_rostering_overrides_file="${overrides_dir}/rhdm-optaweb-employee-rostering-overrides.yaml"
            if [ ! -f "${optaweb_employee_rostering_overrides_file}" ]; then
                log_info "Generating ${optaweb_employee_rostering_overrides_file} ..."
cat <<EOF > "${optaweb_employee_rostering_overrides_file}"
envs:
    - name: "EMPLOYEE_ROSTERING_DISTRIBUTION_ZIP"
      value: "${employee_rostering_distribution_zip}"
    - name: "EMPLOYEE_ROSTERING_DISTRIBUTION_WAR"
      value: "${employee_rostering_distribution_war}"
artifacts:
    - name: "ADD_ONS_DISTRIBUTION_ZIP"
      target: "add_ons_distribution.zip"
      #     ${add_ons_distribution_zip}
      md5: "${add_ons_distribution_md5}"
EOF
            else
                log_info "File ${optaweb_employee_rostering_overrides_file} already generated."
            fi
        fi
    fi
}

handle_rhpam_artifacts() {
    local full_version=${1}
    local short_version=${2}
    local build_type=${3}
    local build_date=${4}
    local product=${5}
    local artifacts_dir="${6}"
    local overrides_dir="${7}"
    local work_dir="${8}"

    local build_file=$(get_build_file "${full_version}" "${build_type}" "${build_date}" "rhpam" "${artifacts_dir}")
    if [ -z "${build_file}" ]; then
        return 1
    fi

    # RHPAM Add-Ons
    local add_ons_distribution_zip
    local add_ons_distribution_md5
    if product_matches "${product}" "rhpam" "controller" || product_matches "${product}" "rhpam" "smartrouter" ; then
        local add_ons_distribution_url=$(get_artifact_url "rhpam.addons.latest.url" "${build_file}")
        add_ons_distribution_zip=$(get_artifact_name "${add_ons_distribution_url}")
        local add_ons_distribution_file="${artifacts_dir}/${add_ons_distribution_zip}"
        if download "${add_ons_distribution_url}" "${add_ons_distribution_file}" ; then
            if cache "${add_ons_distribution_file}" "${work_dir}"; then
                add_ons_distribution_md5=$(get_sum "md5" "${add_ons_distribution_file}")
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHPAM Business Central
    local business_central_distribution_url
    local business_central_distribution_zip
    local business_central_distribution_file
    local business_central_distribution_md5
    if product_matches "${product}" "rhpam" "businesscentral" || product_matches "${product}" "rhpam" "kieserver" ; then
        business_central_distribution_url=$(get_artifact_url "rhpam.business-central-eap7.latest.url" "${build_file}")
        business_central_distribution_zip=$(get_artifact_name "${business_central_distribution_url}")
        business_central_distribution_file="${artifacts_dir}/${business_central_distribution_zip}"
        if download "${business_central_distribution_url}" "${business_central_distribution_file}" ; then
            if cache "${business_central_distribution_file}" "${work_dir}"; then
                business_central_distribution_md5=$(get_sum "md5" "${business_central_distribution_file}")
                if product_matches "${product}" "rhpam" "businesscentral" ; then
                    local businesscentral_overrides_file="${overrides_dir}/rhpam-businesscentral-overrides.yaml"
                    if [ ! -f "${businesscentral_overrides_file}" ]; then
                        log_info "Generating ${businesscentral_overrides_file} ..."
cat <<EOF > "${businesscentral_overrides_file}"
artifacts:
    - name: "BUSINESS_CENTRAL_DISTRIBUTION_ZIP"
      target: "business_central_distribution.zip"
      #     ${business_central_distribution_zip}
      md5: "${business_central_distribution_md5}"
EOF
                    else
                        log_info "File ${businesscentral_overrides_file} already generated."
                    fi
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHPAM Business Central Monitoring
    if product_matches "${product}" "rhpam" "businesscentral-monitoring" ; then
        local business_central_monitoring_distribution_url=$(get_artifact_url "rhpam.monitoring.latest.url" "${build_file}")
        if [ -z "${business_central_monitoring_distribution_url}" ]; then
            if [ -z "${business_central_distribution_url}" ]; then
                business_central_distribution_url=$(get_artifact_url "rhpam.business-central-eap7.latest.url" "${build_file}")
            fi
            business_central_monitoring_distribution_url=$(echo "${business_central_distribution_url}" | sed -e 's/business-central-eap7-deployable/monitoring-ee7/')
            log_warning "Property \"rhpam.monitoring.latest.url\" is not defined. Attempting ${business_central_monitoring_distribution_url} ..."
        fi
        local business_central_monitoring_distribution_zip=$(get_artifact_name "${business_central_monitoring_distribution_url}")
        local business_central_monitoring_distribution_file="${artifacts_dir}/${business_central_monitoring_distribution_zip}"
        if download "${business_central_monitoring_distribution_url}" "${business_central_monitoring_distribution_file}" ; then
            if cache "${business_central_monitoring_distribution_file}" "${work_dir}"; then
                local business_central_monitoring_distribution_md5=$(get_sum "md5" "${business_central_monitoring_distribution_file}")
                local businesscentral_monitoring_overrides_file="${overrides_dir}/rhpam-businesscentral-monitoring-overrides.yaml"
                if [ ! -f "${businesscentral_monitoring_overrides_file}" ]; then
                    log_info "Generating ${businesscentral_monitoring_overrides_file} ..."
cat <<EOF > "${businesscentral_monitoring_overrides_file}"
artifacts:
    - name: "BUSINESS_CENTRAL_MONITORING_DISTRIBUTION_ZIP"
      target: "business_central_monitoring_distribution.zip"
      #     ${business_central_monitoring_distribution_zip}
      md5: "${business_central_monitoring_distribution_md5}"
EOF
                else
                    log_info "File ${businesscentral_monitoring_overrides_file} already generated."
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHPAM Controller
    if product_matches "${product}" "rhpam" "controller" ; then
        local controller_distribution_zip="rhpam-${short_version}-controller-ee7.zip"
        local controller_overrides_file="${overrides_dir}/rhpam-controller-overrides.yaml"
        if [ ! -f "${controller_overrides_file}" ]; then
            log_info "Generating ${controller_overrides_file} ..."
cat <<EOF > "${controller_overrides_file}"
envs:
    - name: "CONTROLLER_DISTRIBUTION_ZIP"
      value: "${controller_distribution_zip}"
artifacts:
    - name: "ADD_ONS_DISTRIBUTION_ZIP"
      target: "add_ons_distribution.zip"
      #     ${add_ons_distribution_zip}
      md5: "${add_ons_distribution_md5}"
EOF
        else
            log_info "File ${controller_overrides_file} already generated."
        fi
    fi

    # RHPAM KIE Server
    if product_matches "${product}" "rhpam" "kieserver" ; then
        local kie_server_distribution_url=$(get_artifact_url "rhpam.kie-server.ee8.latest.url" "${build_file}")
        local kie_server_distribution_zip=$(get_artifact_name "${kie_server_distribution_url}")
        local kie_server_distribution_file="${artifacts_dir}/${kie_server_distribution_zip}"
        if download "${kie_server_distribution_url}" "${kie_server_distribution_file}" && [ -f "${kie_server_distribution_file}" ]; then
            if cache "${kie_server_distribution_file}" "${work_dir}"; then
                local kie_server_distribution_md5=$(get_sum "md5" "${kie_server_distribution_file}")
                local jbpm_wb_kie_server_backend_path=$(get_zip_path "${business_central_distribution_file}" '.*jbpm-wb-kie-server-backend.*\.jar')
                local jbpm_wb_kie_server_backend_jar=$(get_artifact_name "${jbpm_wb_kie_server_backend_path}")
                local kieserver_overrides_file="${overrides_dir}/rhpam-kieserver-overrides.yaml"
                if [ ! -f "${kieserver_overrides_file}" ]; then
                    log_info "Generating ${kieserver_overrides_file} ..."
cat <<EOF > "${kieserver_overrides_file}"
envs:
    - name: "JBPM_WB_KIE_SERVER_BACKEND_JAR"
      value: "${jbpm_wb_kie_server_backend_jar}"
artifacts:
    - name: "KIE_SERVER_DISTRIBUTION_ZIP"
      target: "kie_server_distribution.zip"
      #     ${kie_server_distribution_zip}
      md5: "${kie_server_distribution_md5}"
    - name: "BUSINESS_CENTRAL_DISTRIBUTION_ZIP"
      target: "business_central_distribution.zip"
      #     ${business_central_distribution_zip}
      md5: "${business_central_distribution_md5}"
EOF
                else
                    log_info "File ${kieserver_overrides_file} already generated."
                fi
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # RHPAM Smart Router
    if product_matches "${product}" "rhpam" "smartrouter" ; then
        local kie_router_distribution_jar="rhpam-${short_version}-smart-router.jar"
        local smartrouter_overrides_file="${overrides_dir}/rhpam-smartrouter-overrides.yaml"
        if [ ! -f "${smartrouter_overrides_file}" ]; then
            log_info "Generating ${smartrouter_overrides_file} ..."
cat <<EOF > "${smartrouter_overrides_file}"
envs:
    - name: "KIE_ROUTER_DISTRIBUTION_JAR"
      value: "${kie_router_distribution_jar}"
artifacts:
    - name: "ADD_ONS_DISTRIBUTION_ZIP"
      target: "add_ons_distribution.zip"
      #     ${add_ons_distribution_zip}
      md5: "${add_ons_distribution_md5}"
EOF
        else
            log_info "File ${smartrouter_overrides_file} already generated."
        fi
    fi
}

main() {
    local args
    IFS=' ' read -r -a args <<< "$(echo ${@})"
    local build_tool="build-overrides"
    local full_version
    local cache_artifact
    local cache_artifact_examples="/tmp/${build_tool}/artifact.zip or http://${build_tool}.io/artifact.zip"
    local cache_list
    local cache_list_examples="/tmp/${build_tool}/artifact-list.txt or http://${build_tool}.io/artifact-list.txt"
    local build_type
    local build_type_default="nightly"
    local build_date
    local build_date_default=$(date --date="1 day ago" '+%Y%m%d')
    local products_valid=( all \
        rhdm rhdm-controller rhdm-decisioncentral rhdm-kieserver rhdm-optaweb-employee-rostering \
        rhpam rhpam-businesscentral rhpam-businesscentral-monitoring rhpam-controller rhpam-kieserver rhpam-smartrouter )
    local product_default="all"
    local version_example="7.4.0"
    local default_dir_example="/tmp/${build_tool}/${build_type_default}/${build_date_default}/${version_example}"
    local default_dir
    local artifacts_dir
    local overrides_dir
    local work_dir
    local usage_help
    local OPTIND opt
    while getopts ":v:c:C:t:b:p:d:a:o:w:h:" opt ${args[@]}; do
        case "${opt}" in
            v)         full_version="${OPTARG^^}" ;;
            c)       cache_artifact="${OPTARG}"   ;;
            C)           cache_list="${OPTARG}"   ;;
            t)           build_type="${OPTARG,,}" ;;
            b)           build_date="${OPTARG}"   ;;
            p)              product="${OPTARG,,}" ;;
            d)          default_dir="${OPTARG}"   ;;
            a)        artifacts_dir="${OPTARG}"   ;;
            o)        overrides_dir="${OPTARG}"   ;;
            w)             work_dir="${OPTARG}"   ;;
            h)           usage_help="${OPTARG,,}" ;;
           \?) log_error "Invalid arg: ${OPTARG}" ;;
        esac
    done
    shift $((OPTIND -1))
    if [ -n "${usage_help}" ] || [[ " $(echo ${args[*]})" =~ .*\ -h.* ]]; then
        # usage/help
        log_help "Usage: ${build_tool}.sh [-v \"#.#.#\"] [-c \"CACHE_ARTIFACT\"] [-C \"CACHE_LIST\"] [-t \"${build_type_default}\"] [-b \"YYYYMMDD\"] [-p \"${product_default}\"] [-d \"DEFAULT_DIR\"] [-a \"ARTIFACT_DIR\"] [-o \"OVERRIDES_DIR\"] [-w \"WORK_DIR\"] [-h]"
        log_help "-v = [v]ersion (required unless -c or -C is defined; format: major.minor.micro; example: ${version_example})"
        log_help "-c = [c]ache artifact (optional; a local artifact to cache, or a remote one starting with \"http(s)://\"; examples: ${cache_artifact_examples})"
        log_help "-C = [C]ache list (optional; a local text file containing a list of artifacts to cache, or a remote one starting with \"http(s)://\"; examples: ${cache_list_examples})"
        log_help "-t = [t]ype of build (optional; default: ${build_type_default}; allowed: nightly, staging, candidate, cache)"
        log_help "-b = [b]uild date (optional; default: ${build_date_default})"
        local ifs_orig=${IFS}
        IFS=","
        log_help "-p = [p]roduct (optional; default: all; allowed: ${products_valid[*]})";
        IFS=${ifs_orig}
        log_help "-d = [d]efault directory (optional; default example: ${default_dir_example})"
        log_help "-a = [a]rtifacts directory (optional; default: default directory)"
        log_help "-o = [o]verrides directory (optional; default: default directory)"
        log_help "-w = [w]orking directory used by cekit (optional; default: the cekit default)"
        log_help "-h = [h]elp / usage"
    elif [ -z "${full_version}" ] && [ -z "${cache_artifact}" ] && [ -z "${cache_list}" ]; then
        log_error "Version (-v), cache artifact (-c), or cache list (-C) is required. Run ${build_tool}.sh -h for help."
    else
        # parse version
        local version_array
        local short_version
        if [ -n "${full_version}" ]; then
            IFS='.' read -r -a version_array <<< "${full_version}"
            short_version="${version_array[0]}.${version_array[1]}"
            log_debug "Full version: ${full_version}"
            log_debug "Short version: ${short_version}"
        else
            log_warning "No version defined."
        fi

        # build type
        if [ -z "${build_type}" ]; then
            if [ -n "${full_version}" ]; then
                build_type="${build_type_default}"
            else
                build_type="cache"
            fi
        elif [ "${build_type}" != "nightly" ] && [ "${build_type}" != "staging" ] && [ "${build_type}" != "candidate" ] && [ "${build_type}" != "cache" ] ; then
            log_error "Build type not recognized. Must be nightly, staging, candidate, or cache. Run ${build_tool}.sh -h for help."
            return 1
        fi
        log_debug "Build type: ${build_type}"

        # build date
        if [ -z "${build_date}" ]; then
            build_date="${build_date_default}"
        fi
        log_debug "Build date: ${build_date}"

        # default directory
        if [ -z "${default_dir}" ]; then
            local build_dir="/tmp/${build_tool}/${build_type}/${build_date}"
            if [ -n "${full_version}" ]; then
                default_dir="${build_dir}/${full_version}"
            else
                default_dir="${build_dir}/cache"
            fi
        fi

        # artifacts directory
        if [ -z "${artifacts_dir}" ]; then
            artifacts_dir="${default_dir}"
        fi
        if mkdir -p "${artifacts_dir}" ; then
            log_debug "Artifacts dir: ${artifacts_dir}"
        else
            log_error "Artifacts dir: ${artifacts_dir} unusable."
            return 1
        fi

        # overrides directory
        if [ -z "${overrides_dir}" ]; then
            overrides_dir="${default_dir}"
        fi
        if mkdir -p "${overrides_dir}" ; then
            log_debug "Overrides dir: ${overrides_dir}"
        else
            log_error "Overrides dir: ${overrides_dir} unusable."
            return 1
        fi

        # cache
        if [ -n "${cache_artifact}" ]; then
            handle_cache_artifact "${cache_artifact}" "${artifacts_dir}" "${work_dir}"
        fi
        if [ -n "${cache_list}" ]; then
            handle_cache_list "${cache_list}" "${artifacts_dir}" "${work_dir}"
        fi

        # product
        if [ -n "${full_version}" ] && [ "${build_type}" != "cache" ]; then
            if [ -z "${product}" ]; then
                product="${product_default}"
            fi
            local product_valid="false"
            for pv in ${products_valid[@]}; do
                if [ "${pv}" = "${product}" ]; then
                    product_valid="true"
                    break
                fi
            done
            if [ "${product_valid}" = "true" ] ; then
                log_debug "Product: ${product}"
            else
                log_error "Invalid product: ${product}"
                return 1
            fi

            # handle artifacts
            if [ "${product}" = "all" ] || [[ "${product}" =~ rhdm.* ]]; then
                handle_rhdm_artifacts "${full_version}" "${short_version}" "${build_type}" "${build_date}" "${product}" "${artifacts_dir}" "${overrides_dir}" "${work_dir}"
            fi
            if [ "${product}" = "all" ] || [[ "${product}" =~ rhpam.* ]]; then
                handle_rhpam_artifacts "${full_version}" "${short_version}" "${build_type}" "${build_date}" "${product}" "${artifacts_dir}" "${overrides_dir}" "${work_dir}"
            fi
        fi
    fi
}

main $@
