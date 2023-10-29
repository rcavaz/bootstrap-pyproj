#!/usr/bin/bash
# set -x


# region - Dependencies

requires_command() {
    command -v "$1" >/dev/null && return
    printf 'Unknown command: %s' "$1" && exit 1
}

install_dependencies() {
    local path=$1
    pushd $path
    xargs sudo apt-get -y install >/dev/null < <(cat *.dependencies.txt)
    popd
}

# endregion


# region - Python Virtual Environment

_get_latest_py_version() {
    pyenv install --list \
    | grep -iv [a-z] \
    | awk '{print $1}' \
    | tail -1
}

_select_python_version() {
    read default < <(_get_latest_py_version)
    read -p "PYTHON_VERSION ($default): " user_selection
    [[ -z $user_selection ]] \
        && printf -v PYTHON_VERSION "%s" $default \
        || printf -v PYTHON_VERSION "%s" $user_selection
    export PYTHON_VERSION
}

_select_pyenv_version() {
    read default < <(basename $PWD)
    read -p "PYENV_VERSION ($default): " user_selection
    [[ -z $user_selection ]] \
        && printf -v PYENV_VERSION "%s" $default \
        || printf -v PYENV_VERSION "%s" $user_selection
    export PYENV_VERSION
}

configure_envrc() {
    _select_python_version
    _select_pyenv_version

    local path=$1
    envsubst > .envrc < $path/envrc.example
    direnv allow
}

configure_virtualenv() {
    pyenv install --skip-existing $PYTHON_VERSION
    pyenv virtualenv $PYTHON_VERSION $PYENV_VERSION
    pyenv local $PYENV_VERSION
    pip install --upgrade pip
}

# endregion


# region - Commands

check_requirements() {
    requires_command 'envsubst'
    requires_command 'pyenv'
}

uninstall() {
    if [[ -n $PYENV_VERSION ]]; then
        pyenv uninstall -f $PYENV_VERSION
        rm .python-version > /dev/null
    fi

    if [ -f .envrc ]; then
        direnv deny
        rm .envrc
    fi
}

# endregion


# -*- Main -*-

main() {
    local path=${1}
    local opt=${2:-install}

    case "${opt}" in
        install)
                check_requirements
                install_dependencies $(dirname $path)
                configure_envrc $(dirname $path)
                configure_virtualenv
            ;;
        uninstall)
                uninstall
            ;;
    esac
}

main $0 $1
