#!/bin/bash

set -e

DEBUG=
GIT_USER=${GIT_USER:-"Your Name"}
GIT_EMAIL=${GIT_EMAIL:-"yourname@email.com"}
WORK_DIR=$(pwd)/build-temp

function help()
{
    echo "usage: build-osbs.sh [options]"
    echo
    echo "Run a cekit osbs build of an rhba image component based on a nightly build of the upstream kie repos"
    echo
    echo "For each of the options below, the names of the arguments are environment variables that may be set"
    echo "instead of using the particular option on the invocation"
    echo ""
    echo "Required:"
    echo "  -v PROD_VERSION           Version being built. Passed to the build-overrides.sh -v option"
    echo "  -c PROD_COMPONENT         Component for which an image is being built. Valid choices are:"
    echo "                            rhpam-businesscentral, rhpam-businesscentral-monitoring,"
    echo "                            rhpam-controller, rhpam-kieserver, rhpam-smartrouter, rhpam-process-migration"
    echo "  -t OSBS_BUILD_TARGET      Build target for osbs, for example rhba-7.3-openshift-containers-candidate"
    echo ""
    echo "Optional:"
    echo "  -h                        Print this help message"
    echo "  -p KERBEROS_PRINCIPAL     Kerberos principal to use with to access build systems. If not specified,"
    echo "                            the script assumes there is a valid kerberos ticket in force. If it is specified"
    echo "                            then one of KERBEROS_KEYTAB or KERBEROS_PASSWORD is required."
    echo "  -k KERBEROS_KEYTAB        Path to a keytab file for KERBEROS_PRINCIPAL if no KERBEROS_PASSWORD is specified."
    echo "  -s KERBEROS_PASSWORD      Password for KERBEROS_PRINCIPAL (a keytab file may be used instead via KERBEROS_KEYTAB)"
    echo "  -i OSBS_BUILD_USER        Maps to the build-osbs-user option for cekit (ie the user for rhpkg commands)"
    echo "                            The default will be KERBEROS_PRINCIPAL if this is not set"
    echo "  -b BUILD_DATE             The date of the nightly build to access. Passed to the build-overrides.sh -b option if set"
    echo "  -w WORK_DIR               The working directory used for generating overrides, cekit cache, etc. Default is ./build-temp."
    echo "  -u GIT_USER               User config for git commits to internal repositories. Default is 'Your Name'"
    echo "  -e GIT_EMAIL              Email config for git commits to internal repositories. Default is 'yourname@email.com'"
    echo "  -o CEKIT_BUILD_OPTIONS    Additional options to pass through to the cekit build command, should be quoted"
    echo "  -l CEKIT_CACHE_LOCAL      Comma-separated list of urls to download and add to the local cekit cache"
    echo "  -g                        Debug setting, currently sets verbose flag on cekit commands"
}


function get_short_version() {
  local version_array
  local short_version=$1
  IFS='.' read -r -a version_array <<< "$1"
  if [ ${#version_array[@]} -gt 1 ]; then
      short_version="${version_array[0]}.${version_array[1]}"
  fi
  echo $short_version
}

function check_for_required_envs()
{
    if [ -z "$GIT_EMAIL" ]; then
        echo "No git email specified with GIT_EMAIL"
        exit -1
    fi
    if [ -z "$GIT_USER" ]; then
        echo "No git user specified with GIT_USER"
        exit -1
    fi
    if [ -z "$PROD_VERSION" ]; then
        echo "No version specified with PROD_VERSION"
        exit -1
    fi
    if [ -z "$PROD_COMPONENT" ]; then
        echo "No component specified with PROD_COMPONENT"
        exit -1
    else
        case "$PROD_COMPONENT" in
            rhpam-businesscentral | \
            rhpam-businesscentral-monitoring | \
            rhpam-controller | \
            rhpam-kieserver | \
            rhpam-process-migration | \
            rhpam-smartrouter)
                ;;
            *)
                echo Invalid subcomponent specified with PROD_COMPONENT
                exit -1
                ;;
        esac
    fi
    if [ -z "$OSBS_BUILD_TARGET" ]; then
        echo "No build target specified with OSBS_BUILD_TARGET"
        exit -1
    fi
}

function get_kerb_ticket() {
    set +e
    if [ -n "$KERBEROS_PASSWORD" ]; then
        echo "$KERBEROS_PASSWORD" | kinit "$KERBEROS_PRINCIPAL"
        klist
        if [ "$?" -ne 0 ]; then
            echo "Failed to get kerberos token for $KERBEROS_PRINCIPAL with password"
            exit -1
        fi
    elif [ -n "$KERBEROS_KEYTAB" ]; then
        kinit -k -t "$KERBEROS_KEYTAB" "$KERBEROS_PRINCIPAL"
        klist
        if [ "$?" -ne 0 ]; then
            echo "Failed to get kerberos token for $KERBEROS_PRINCIPAL with $KERBEROS_KEYTAB"
            exit -1
        fi
    else
        echo "No kerberos password or keytab specified with KERBEROS_PASSWORD or KERBEROS_KEYTAB"
        exit -1
    fi
    set -e
}

function hello_koji() {
    if [ -n "$DEBUG" ]; then
        cat  /etc/koji.conf.d/brewkoji.conf
        KRB5_TRACE=/dev/stdout koji -d hello
    fi
}


function set_git_config() {
    git config --global user.email "$GIT_EMAIL"
    git config --global user.name  "$GIT_USER"
    git config --global core.pager ""
}

function get_extra_cekit_overrides_options()
{
    local gen_overrides_dir=$1
    overrides=
    artifactoverrides=

    if [ -f "$gen_overrides_dir/$PROD_COMPONENT-overrides.yaml" ]; then
        overrides="--overrides-file $gen_overrides_dir/$PROD_COMPONENT-overrides.yaml"
    fi

    # If there is an artifact-overrides.yaml in the local dir, use it
    has_artifacts=$(cat artifact-overrides.yaml |  python3 -c 'import yaml,sys;obj=yaml.load(sys.stdin, Loader=yaml.FullLoader); print(obj["artifacts"])')
    if [ -f "artifact-overrides.yaml" ] && [ "${has_artifacts}" != "None" ]; then
        artifactoverrides="--overrides-file artifact-overrides.yaml"
    fi
}

function handle_cache_urls()
{
    # Parse and cache extra urls to add to the local cekit cache
    if [ -n "$1" ]; then
        local IFS=,
        local urllist=($1)
        for url in "${urllist[@]}"; do
            echo build-overrides.sh -c $url $bo_options
            build-overrides.sh -c $url $bo_options
        done
    fi
}

function generate_overrides_files()
{
    echo build-overrides.sh -v $PROD_VERSION -t nightly -p $PROD_COMPONENT $bo_options
    build-overrides.sh -v $PROD_VERSION -t nightly -p $PROD_COMPONENT $bo_options
}

while getopts gu:e:v:c:t:o:r:n:d:p:k:s:b:l:i:w:h option; do
    case $option in
        g)
            DEBUG=true
            ;;
        u)
            GIT_USER=$OPTARG
            ;;
        e)
            GIT_EMAIL=$OPTARG
            ;;
        v)
            PROD_VERSION=$OPTARG
            ;;
        c)
            PROD_COMPONENT=$OPTARG
            ;;
        t)
            OSBS_BUILD_TARGET=$OPTARG
            ;;
        o)
            CEKIT_BUILD_OPTIONS=$OPTARG
            ;;
        p)
            KERBEROS_PRINCIPAL=$OPTARG
            ;;
        k)
            KERBEROS_KEYTAB=$OPTARG
            ;;
        s)
            KERBEROS_PASSWORD=$OPTARG
            ;;
        b)
            BUILD_DATE=$OPTARG
            ;;
        l)
            CEKIT_CACHE_LOCAL=$OPTARG
            ;;
        i)
            OSBS_BUILD_USER=$OPTARG
            ;;
        w)
            WORK_DIR=$OPTARG
            ;;
        h)
            help
            exit 0
            ;;
        *)
            ;;
    esac
done
shift $((OPTIND-1))

mkdir -p $WORK_DIR

# Make sure we have build-overrides.sh on our path
set +e
$(command -v "build-overrides.sh" &> /dev/null)
res=$?
set -e
if [ "$res" -ne 0 ]; then
    echo No build-overrides.sh found on the current path, it needs to be added
    exit -1
fi

# Set common options for build-overrides.sh calls
cekit_cache_dir="$WORK_DIR/.cekit"
gen_overrides_dir="$WORK_DIR/build-overrides"
bo_options="-w $cekit_cache_dir -d $gen_overrides_dir"
if [ -n "$BUILD_DATE" ]; then
    bo_options+=" -b $BUILD_DATE"
fi
bo_options+=" --no-color"

check_for_required_envs
set_git_config

if [ -n "$KERBEROS_PRINCIPAL" ]; then
    get_kerb_ticket
    # overrides the OSBS_BUILD_USER if it is not set and KERBEROS principal is in use
    if [ ! -n "$OSBS_BUILD_USER" ]; then
      echo "setting OSBS_BUILD_USER to KERBEROS_PRINCIPAL"
      OSBS_BUILD_USER=$KERBEROS_PRINCIPAL
    fi
else
    echo No kerberos principal specified, assuming there is a current kerberos ticket
fi

# load specific urls into the local cekit cache based on any files stored in
# /opt/rhba/overrides/<branch> and an optional list in CEKIT_CACHE_LOCAL
handle_cache_urls "$CEKIT_CACHE_LOCAL"

generate_overrides_files
get_extra_cekit_overrides_options $gen_overrides_dir

debug=
if [ -n "$DEBUG" ]; then
    debug="--verbose"
fi

builduser=
if [ -n "$OSBS_BUILD_USER" ]; then
    builduser="$OSBS_BUILD_USER"
fi

CEKIT_COMMAND="cekit --redhat $debug --work-dir=$cekit_cache_dir build --overrides-file branch-overrides.yaml $overrides $artifactoverrides osbs --user \"$builduser\""
# Invoke cekit and respond with Y to any prompts
echo -e "########## Using CeKit version: `cekit --version`.\nExecuting the following CeKit build Command: \n$CEKIT_COMMAND"
exec $CEKIT_COMMAND