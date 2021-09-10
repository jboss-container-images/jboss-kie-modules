#!/usr/bin/env bash

function trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var##*( )}"
    # remove trailing whitespace characters
    var="${var%%*( )}"
    echo -n "$var"
}