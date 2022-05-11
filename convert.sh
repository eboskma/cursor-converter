#!/usr/bin/env bash

set -e
set -u
set -o pipefail

function usage() {
    echo "cursor-converter"
    echo ""
    echo "Usage:"
    echo "  cursor-converter <INPUT> <OUTPUT>"
    echo ""
    echo "Arguments:"
    echo "  INPUT:   Directory containing the Windows cursors"
    echo "  OUTPUT:  Directory to put the X cursors in"
}

function check_params() {
    input="${1}"
    output="${2}"

    if [[ ! -d "${input}" ]]; then
        echo "Input '${input}' is not a directory"
        exit 2
    fi

    if [[ ! -d "${output}" ]]; then
        mkdir -p "${output}"
    fi
}

function convert_ani() {
    echo "Converting .ani cursors"
    input="${1}"
    output="${2}"

    for cursor in "${input}"/*.ani; do
        cursor_name="$(basename "${cursor// /_}" .ani)"
        
        mkdir -p "${output}/${cursor_name}"
        cp "${cursor}" "${output}/${cursor_name}/${cursor_name}.ani"
        pushd "${output}/${cursor_name}" > /dev/null
        ani2ico "${cursor_name}.ani"
        rm "${cursor_name}.ani"

        for ico in "${cursor_name}"*.ico; do
            ico_name="$(basename "${ico}" .ico)"
            convert "${ico}" "${ico_name}.png"
            identify -format '%w 1 1 %f 200\n' "${ico_name}"*.png >> "${cursor_name}.xcg"
        done

        xcursorgen "${cursor_name}.xcg" "${cursor_name}"

        rm ./*.ico ./*.png "${cursor_name}.xcg"
        
        popd > /dev/null
    done
}

function convert_cur() {
    echo "Converting .cur cursors"
    input="${1}"
    output="${2}"

    for cursor in "${input}"/*.cur; do
        cursor_name="$(basename "${cursor// /_}" .cur)"

        mkdir -p "${output}/${cursor_name}"

        pushd "${output}/${cursor_name}" > /dev/null
        convert "${cursor}" "${cursor_name}.png"
        identify -format '%w 1 1 %f\n' "${cursor_name}"*.png > "${cursor_name}.xcg"
        xcursorgen "${cursor_name}.xcg" "${cursor_name}"

        rm ./*.png "${cursor_name}.xcg"
        popd > /dev/null
    done
}

function main() {
    if [[ $# -ne 2 ]]; then
        usage
        exit 1
    fi

    echo "Converting cursors in '$1' and placing result in '$2'"

    check_params "${1}" "${2}"
    convert_ani "${1}" "${2}"
    convert_cur "${1}" "${2}"
}

main "${@}"

