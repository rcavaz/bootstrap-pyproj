#!/usr/bin/bash
# set -x

requires_command() {
    command -v "$1" >/dev/null && return
    printf 'Unknown command: %s' "$1" && exit 1
}

install_dependencies() {
    xargs sudo apt-get -y install >/dev/null < <(cat *.dependencies.txt)
}

configure_envrc() {
    printf "PYTHON_VERSION: "; read PYTHON_VERSION
    [[ -z $PYTHON_VERSION ]] && exit 1

    read PYENV_VERSION < <(basename $PWD)
    envsubst > .envrc < envrc.example
    direnv allow
}

install() {
    requires_command 'envsubst'
    requires_command 'pyenv'

    install_dependencies
    configure_envrc

    pyenv install --skip-existing $PYTHON_VERSION
    pyenv virtualenv $PYTHON_VERSION $PYENV_VERSION
    pyenv local $PYENV_VERSION
    pip install --upgrade pip
    # pip install -r requirements.txt

    # pre-commit install
    # pre-commit install --hook-type commit-msg
}

uninstall() {
    pyenv uninstall -f $PYENV_VERSION && rm .python-version
    direnv deny && rm .envrc
}

# -*- Main -*-

main() {
    local path=${1}
    local opt=${2:-install}

    pushd $(dirname $path)

    case "${opt}" in
        install)
                install
            ;;
        uninstall)
                uninstall
            ;;
    esac

    popd
}

main $0 $1
