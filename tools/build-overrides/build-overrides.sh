#!/usr/bin/env bash

# Required:
#   awk, bash, date, dirname, echo, env, find, getopts, grep, mkdir, read, realpath
#   curl
#   unzip, zipinfo
#   md5sum
#   cekit, cekit-cache 2.2.4+
# Optional:
#   sha1sum, sha256sum, sha512sum

clear_env() {
    unset NO_COLOR
}

log() {
    local msg="${1}"
    local color="${2}"
    if [ -n "${color}" ] && [ "${NO_COLOR}" != "enabled" ]; then
        echo 1>&2 -e "\033[0;${color}m${msg}\033[0m"
    else
        echo 1>&2 -e "${msg}"
    fi
}

log_help() {
    # color: none
    log "${1}"
}

log_debug() {
    # color: blue
    log "[DEBUG] ${1}" "34"
}

log_info() {
    # color: green
    log " [INFO] ${1}" "32"
}

log_warn() {
    # color: yellow
    log " [WARN] ${1}" "33"
}

log_error() {
    # color: red
    log "[ERROR] ${1}" "31"
}

validate_cekit_version() {
    local cekit_version=$(cekit --version 2>&1)
    local cekit_cache_version=$(cekit-cache --version 2>&1)
    if [ "${cekit_version}" != "${cekit_cache_version}" ]; then
        log_error "cekit ${cekit_version} does not match cekit-cache ${cekit_cache_version}"
        clear_env
        exit 1
    fi
    local cekit_exe=$(which cekit)
    local cekit_cache_exe=$(which cekit-cache)
    if [ "$(realpath $(dirname ${cekit_exe}))" != "$(realpath $(dirname ${cekit_cache_exe}))" ]; then
        # See "Warning" here:
        # https://docs.cekit.io/en/latest/handbook/caching.html#managing-cache
        log_error "${cekit_exe} does not share the same path as ${cekit_cache_exe}"
        clear_env
        exit 1
    fi
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
    local sum_cmd="${algo}sum"
    if (which "${sum_cmd}" > /dev/null 2>&1) ; then
        local checksum=$("${sum_cmd}" "${file}" | awk '{ print $1 }')
        echo -n "${checksum}"
        return 0
    else
        log_warn "Command \"${sum_cmd}\" not found; skipping algorithm \"${algo}\"..."
        return 1
    fi
}

cache() {
    local file=${1}
    local work_dir=${2}
    # if work_dir is null, set the default
    if [ -z "${work_dir}" ]; then
        work_dir="${HOME}/.cekit"
    fi
    local name=$(get_artifact_name "${file}")
    local md5=$(get_sum "md5" "${file}")
    local code=1
    if [ -d "${work_dir}/cache" ]; then
        local grep_yaml
        for Y in $(grep -ln "${name}" ${work_dir}/cache/*.yaml) ; do
            grep_yaml=$(grep "md5: ${md5}" "${Y}")
            code=$?
            if [ ${code} = 0 ] ; then
                log_info "File ${file} already cached."
                log_debug "Cache entry: ${Y}"
                break
            fi
        done
    fi
    if [ ${code} != 0 ] ; then
        local cekit_version=$(cekit-cache --version 2>&1)
        local cekit_version_array
        IFS='.' read -r -a cekit_version_array <<< "${cekit_version}"
        cekit_version="${cekit_version_array[0]}"
        log_info "Caching ${file} ..."
        local sum_opts="--md5 ${md5}"
        local sha1=$(get_sum "sha1" "${file}")
        if [ -n "${sha1}" ]; then
            sum_opts+=" --sha1 ${sha1}"
        fi
        local sha256=$(get_sum "sha256" "${file}")
        if [ -n "${sha256}" ]; then
            sum_opts+=" --sha256 ${sha256}"
        fi
        if [ "${cekit_version}" = "3" ]; then
            local sha512=$(get_sum "sha512" "${file}")
            if [ -n "${sha512}" ]; then
                sum_opts+=" --sha512 ${sha512}"
            fi
        fi
        cekit-cache --work-dir "${work_dir}" add $sum_opts "${file}"
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
    local work_dir="${3}"
    local cache_item_target=$(get_artifact_name "${cache_item_source}")
    cache_item_target="${artifacts_dir}/${cache_item_target}"
    if [[ "${cache_item_source}" =~ https?://.* ]]; then
        if ! download "${cache_item_source}" "${cache_item_target}" ; then
            return 1
        fi
    elif [ -d "${cache_item_source}" ]; then
            log_debug "${cache_item_source} is a directory; recursing ..."
        for child_item in $(find "${cache_item_source}" -maxdepth 1 -type f -name \*.jar -o -name \*.war -o -name \*.zip); do
            handle_cache_artifact "${child_item}" "${artifacts_dir}" "${work_dir}"
        done
    elif [ -f "${cache_item_source}" ]; then
        local real_cache_item_source=$(realpath "${cache_item_source}")
        local real_cache_item_target=$(realpath "${cache_item_target}")
        if [ "${real_cache_item_source}" = "${real_cache_item_target}" ]; then
            log_warn "File ${cache_item_source} and ${cache_item_target} are the same file."
        else
            if [ -f "${cache_item_target}" ]; then
                log_warn "File ${cache_item_target} already exists; overwriting ..."
            fi
            log_info "Copying ${cache_item_source} to ${cache_item_target} ..."
            if ! cp -f "${cache_item_source}" "${cache_item_target}" ; then
                log_error "Copying to ${cache_item_target} failed."
                return 1
            fi
        fi
    else
        log_warn "File or directory ${cache_item_source} does not exist; skipping ..."
        return 1
    fi
    echo -n "${cache_item_target}"
}

handle_cache_artifact() {
    local cache_artifact_source="${1}"
    local artifacts_dir="${2}"
    local work_dir="${3}"
    local cache_artifact_target
    cache_artifact_target=$(get_cache_item "${cache_artifact_source}" "${artifacts_dir}" "${work_dir}")
    if [ $? = 0 ] && [ -f "${cache_artifact_target}" ]; then
        cache "${cache_artifact_target}" "${work_dir}"
    fi
}

handle_cache_list() {
    local cache_list_source="${1}"
    local artifacts_dir="${2}"
    local work_dir="${3}"
    local cache_list_target
    cache_list_target=$(get_cache_item "${cache_list_source}" "${artifacts_dir}" "${work_dir}")
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
  # ${add_ons_distribution_zip}
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
  # ${decision_central_distribution_zip}
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
  # ${kie_server_distribution_zip}
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
  # ${add_ons_distribution_zip}
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
  # ${business_central_distribution_zip}
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
            log_warn "Property \"rhpam.monitoring.latest.url\" is not defined. Attempting ${business_central_monitoring_distribution_url} ..."
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
  # ${business_central_monitoring_distribution_zip}
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
  # ${add_ons_distribution_zip}
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
  # ${kie_server_distribution_zip}
  md5: "${kie_server_distribution_md5}"
- name: "BUSINESS_CENTRAL_DISTRIBUTION_ZIP"
  target: "business_central_distribution.zip"
  # ${business_central_distribution_zip}
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
  # ${add_ons_distribution_zip}
  md5: "${add_ons_distribution_md5}"
EOF
        else
            log_info "File ${smartrouter_overrides_file} already generated."
        fi
    fi
}

delete_cached_artifacts() {
    local product=${1}
    local product_default="all"
    local products_valid=(all rhdm rhpam)
    local query="rhpam*\|rhdm*"
    if [ -z "${product}" ]; then
        product="${product_default}"
    else
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
            log_error "Invalid product: ${product}. Allowed: ${products_valid[*]}"
            return 1
        fi
    fi

    if [ "${product}" != "all" ]; then
        query="${product}*"
    fi

    for artifact in $(cekit-cache ls | grep -B6 "${query}" | egrep "([0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12})" -o); do
        log_info "Deleting artifact ${artifact} from local cache"
        cekit-cache rm $artifact;
    done
}

main() {
    validate_cekit_version
    local args
    IFS=' ' read -r -a args <<< "$(echo ${@})"
    local build_tool="build-overrides"
    local full_version
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
    local cache_artifact
    local cache_artifact_examples="/tmp/${build_tool}/artifact.zip or /tmp/${build_tool}/artifacts/ or http://${build_tool}.io/artifact.zip"
    local cache_list
    local cache_list_examples="/tmp/${build_tool}/artifact-list.txt or http://${build_tool}.io/artifact-list.txt"
    local delete_product
    local no_color
    local usage_help
    local OPTIND opt
    while getopts ":v:t:b:p:d:a:o:w:c:C:-:h:" opt ${args[@]}; do
        case "${opt}" in
            -)
                arg="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                case "${OPTARG}" in
                    version)            full_version="${arg^^}" ;;
                    build-type)           build_type="${arg,,}" ;;
                    build-date)           build_date="${arg}"   ;;
                    product)                 product="${arg,,}" ;;
                    default-dir)         default_dir="${arg}"   ;;
                    artifacts-dir)     artifacts_dir="${arg}"   ;;
                    overrides-dir)     overrides_dir="${arg}"   ;;
                    work-dir)               work_dir="${arg}"   ;;
                    cache)            cache_artifact="${arg}"   ;;
                    cache-list)           cache_list="${arg}"   ;;
                    delete-cache)     delete_product="${arg}"   ;;
                    no-color)               no_color="${arg,,}" ;;
                    help)                 usage_help="${arg,,}" ;;
                    *) log_error "Invalid arg: --${OPTARG}"     ;;
                esac;;
            v)         full_version="${OPTARG^^}" ;;
            t)           build_type="${OPTARG,,}" ;;
            b)           build_date="${OPTARG}"   ;;
            p)              product="${OPTARG,,}" ;;
            d)          default_dir="${OPTARG}"   ;;
            a)        artifacts_dir="${OPTARG}"   ;;
            o)        overrides_dir="${OPTARG}"   ;;
            w)             work_dir="${OPTARG}"   ;;
            c)       cache_artifact="${OPTARG}"   ;;
            C)           cache_list="${OPTARG}"   ;;
            h)           usage_help="${OPTARG,,}" ;;
           \?) log_error "Invalid arg: ${OPTARG}" ;;
        esac
    done
    shift $((OPTIND -1))
    local all_args=" $(echo ${args[*]})"
    if [ -n "${no_color}" ] || [[ "${all_args}" =~ .*\ (--no-color.*) ]]; then
        NO_COLOR="enabled"
    fi
    local cekit_version=$(cekit --version 2>&1)
    log_info "${build_tool}.sh (cekit ${cekit_version})"
    if [ -n "${usage_help}" ] || [[ "${all_args}" =~ .*\ (-h.*|--help.*) ]]; then
        # usage/help
        log_help "Usage: ${build_tool}.sh [-v \"#.#.#\"] [-t \"${build_type_default}\"] [-b \"YYYYMMDD\"] [-p \"${product_default}\"] [-d \"DEFAULT_DIR\"] [-a \"ARTIFACT_DIR\"] [-o \"OVERRIDES_DIR\"] [-w \"WORK_DIR\"] [-c \"CACHE_ARTIFACT\"] [-C \"CACHE_LIST\"] [-h]"
        log_help "-v | --version = [v]ersion of build (required unless -c or -C is defined; format: major.minor.micro; example: ${version_example})"
        log_help "-t | --build-type = [t]ype of build (optional; default: ${build_type_default}; allowed: nightly, staging, candidate, cache)"
        log_help "-b | --build-date = [b]uild date (optional; default: ${build_date_default})"
        local ifs_orig=${IFS}
        IFS=","
        log_help "-p | --product = [p]roduct (optional; default: all; allowed: ${products_valid[*]})";
        IFS=${ifs_orig}
        log_help "-d | --default-dir = [d]efault directory (optional; default example: ${default_dir_example})"
        log_help "-a | --artifacts-dir = [a]rtifacts directory (optional; default: default directory)"
        log_help "-o | --overrides-dir = [o]verrides directory (optional; default: default directory)"
        log_help "-w | --work-dir = [w]orking directory used by cekit (optional; default: the cekit default)"
        log_help "-c | --cache = [c]ache artifact (optional; a local artifact file or directory of artifacts to cache, or a remote artifact starting with \"http(s)://\"; examples: ${cache_artifact_examples})"
        log_help "-C | --cache-list = [C]ache list (optional; a local text file containing a list of artifacts to cache, or a remote one starting with \"http(s)://\"; examples: ${cache_list_examples})"
        log_help "--delete-cache = deletes local cached artifacts from specified product (optional; default: don't delete anything; allowed: all rhdm rhpam)"
        log_help "--no-color = Suppress terminal color output (optional; default: ANSI escape codes for color will be included)"
        log_help "-h | --help = [h]elp / usage"
    elif [ -z "${full_version}" ] && [ -z "${cache_artifact}" ] && [ -z "${cache_list}" ] && [ -z "${delete_product}" ]; then
        log_error "Version (-v), artifact or directory of artifacts to cache (-c), list file of artifacts to cache (-C), or product artifacts to delete (--delete-cache) is required. Run ${build_tool}.sh -h for help."
    else
        # parse version
        local version_array
        local short_version
        if [ -n "${full_version}" ]; then
            IFS='.' read -r -a version_array <<< "${full_version}"
            short_version="${version_array[0]}.${version_array[1]}"
            log_debug "Full build version: ${full_version}"
            log_debug "Short build version: ${short_version}"
        else
            log_warn "No build version defined."
        fi

        # build type
        if [ -z "${build_type}" ]; then
            if [ -n "${full_version}" ]; then
                build_type="${build_type_default}"
            elif [ -n "${cache_artifact}" ] || [ -n "${cache_list}" ]; then
                build_type="cache"
            else
                build_type="delete cache"
            fi
        elif [ "${build_type}" != "nightly" ] && [ "${build_type}" != "staging" ] && [ "${build_type}" != "candidate" ] && [ "${build_type}" != "cache" ] ; then
            log_error "Build type not recognized. Must be nightly, staging, candidate, or cache. Run ${build_tool}.sh -h for help."
            clear_env
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
            clear_env
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
            clear_env
            return 1
        fi

        # delete artifact cache
        if [ -n "${delete_product}" ]; then
            delete_cached_artifacts "${delete_product}"
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
                clear_env
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
        clear_env
    fi
}

main $@
