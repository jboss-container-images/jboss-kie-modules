#!/bin/sh

export KUBERNETES_SERVICE_PROTOCOL="http"
export KUBERNETES_SERVICE_HOST="localhost"
export KUBERNETES_SERVICE_PORT="8080"

# File from https://github.com/jboss-container-images/jboss-kie-modules/blob/main/os-eap-legacy/os-eap7-launch/added/launch/launch-common.sh

# common subroutines used in various places of the launch scripts

# Finds the environment variable  and returns its value if found.
# Otherwise returns the default value if provided.
#
# Arguments:
# $1 env variable name to check
# $2 default value if environment variable was not set
function find_env() {
  var=${!1}
  echo "${var:-$2}"
}

# Finds the environment variable with the given prefix. If not found
# the default value will be returned. If no prefix is provided will rely on
# find_env
#
# Arguments
#  - $1 prefix. Transformed to uppercase and replace - by _
#  - $2 variable name. Prepended by "prefix_"
#  - $3 default value if the variable is not defined
function find_prefixed_env () {
  local prefix=$1

  if [[ -z $prefix ]]; then
    find_env $2 $3
  else
    prefix=${prefix^^} # uppercase
    prefix=${prefix//-/_} #replace - by _

    local var_name=$prefix"_"$2
    echo ${!var_name:-$3}
  fi
}