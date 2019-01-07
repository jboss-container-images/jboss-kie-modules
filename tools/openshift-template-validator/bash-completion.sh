#!/usr/bin/env bash

_validator_completions() {
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    showOnlyOne="${COMP_WORDS[1]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="validate help"
    allOpts="--file --dir --persist --custom-annotation --template-version --validate-version --verbose --strict --dump --help --disable-defer"

    case "${prev}" in
        validate)
            COMPREPLY=( $(compgen -W "${allOpts}" -- ${cur}) )

            ;;
        -f|--file|-d|--dir)
            return 0
            ;;
        *)
            if [ "${#COMP_WORDS[@]}" == "2" ]; then
                COMPREPLY=($(compgen -W "${opts}" -- "${showOnlyOne}"))
            else
                COMPREPLY=( $(compgen -W "${allOpts[@]}" -- ${cur}) )
            fi
            ;;
    esac
}

complete  -F _validator_completions -o default openshift-template-validator-linux-amd64