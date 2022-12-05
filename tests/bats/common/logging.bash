#!/usr/bin/env bash

function log_info() {
    echo "[INFO]"$1 >&2
}

function log_error() {
    echo "[ERROR]"$1 >&2
}

function log_warning() {
    echo "[WARN]"$1 >&2
}