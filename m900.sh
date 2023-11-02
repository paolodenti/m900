#!/bin/bash

#--------------------------------------------------
# Script to refresh configuration for Snom M900
#
# you need to install sipsak
#
# Author: Walter Trucci - walter at trucci.it
# date: 30-10-2023
#--------------------------------------------------

# Ansi color code variables
red="\e[0;91m"
blue="\e[0;94m"
green="\e[0;92m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

usage() {
    echo "Usage: $0 [ -d <m900 files folder> ] [ -h ]" 1>&2
    echo "-d file folder: directory where the m900 files are stored" 1>&2
    echo "-h: help" 1>&2

    exit 1
}

text() {
    local msg="$1"

    echo -e "${msg}"
}

error() {
    local msg="$1"

    echo -e "${red}${msg}${reset}"
}

fail() {
    local msg="$1"

    echo -e "${red}${msg}${reset}" >&2
    exit 1
}

# the create function add a file with m900 extension with parameter to send with sipsak

create() {
    local name=""
    local id=""
    local m900Ip=""
    local pbxIp=""

    while :; do
        text "Please give me a name ${bold}${uline}without spaces${reset}"
        read name

        if printf "%s" "$name" | grep -E '[ "]' 1>/dev/null; then
            error "The name contains one or more spaces\n"
            text "Please insert data again\n"
        else
            if [ $name ]; then
                text "The name is $name\n"
                break
            else
                error "The string can't be empty$\n"
                text "Please insert data again\n"
            fi
        fi
    done

    while :; do
        text "Please give me the multicell id"
        read id

        if [ -n "$id" ] && [ "$id" -eq "$id" ] 2>/dev/null; then
            if ! ([ $id -ge 1 ] && [ $id -le 512 ]); then
                error "BAD ID need to be in a range from 1 to 512\n"
                text "Please insert data again\n"
            else
                break
            fi
        else
            error "BAD ID need to be in a range from 1 to 512\n"
            text "Please insert data again\n"
        fi
    done

    while :; do
        text "\nPlease give me the M900 IP"
        read m900Ip

        printf "%s" "${m900Ip}" | grep -Eo '^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$' 1>/dev/null
        if ! [ $? -eq 0 ]; then
            error "BAD IP$\n"
            text "Please insert data again\n"
        else
            break
        fi
    done

    while :; do
        text "\nPlease give me the PBX IP"
        read pbxIp

        printf "%s" "${pbxIp}" | grep -Eo '^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$' 1>/dev/null
        if ! [ $? -eq 0 ]; then
            error "BAD IP\n"
            text "Please insert data again\n"
        else
            break
        fi
    done

    cat >"${DIRECTORY}${name}.m900" <<EOF
NOTIFY sip:$id@$m900Ip SIP/2.0
To: sip:$id@$m900Ip
From: sip:sipsak@$pbxIp
CSeq: 10 NOTIFY
Call-ID: 1234@$pbxIp
Event: check-sync;reboot=false
EOF

    text "\nFile created successfully\n"
    sleep 3
}

# the execute function permit to select cell to provision

execute() {
    if compgen -G "${DIRECTORY}*.m900" >/dev/null; then

        while true; do
            text "Please select the M900 name"
            set -- ${DIRECTORY}*.m900

            i=0
            for pathname; do
                i=$((i + 1))
                printf '%d) %s\n' "$i" "$pathname" >&2
            done

            echo -n 'Select m900 cell, or 0 to exit: ' >&2
            read -r reply

            number=$(printf '%s\n' "$reply" | tr -dc '[:digit:]')

            if ! [[ $number =~ ^[0-9]+$ ]]; then
                error "Not a number"
            elif [ "$number" = "0" ]; then
                text 'Bye!'
                exit 0
            elif [ "$number" -gt "$#" ]; then
                text 'Invalid choice, try again'
            else
                break
            fi
        done

        shift "$((number - 1))"
        provisioning $1

    else
        error "No cell configured.\nPlease create a new cell first!${reset}"
        sleep 3
    fi
}

# the provisioning function send command to the m900

provisioning() {
    local file="$1"

    idCell="$(cat $file | awk -F"[:@]" '/To:/{print $3}')"
    ipCell="$(cat $file | awk -F"[:@]" '/To:/{print $4}')"
    ipPbx="$(cat $file | awk -F"[:@]" '/From:/{print $4}')"

    sipsak -vvv -G -s sip:$idCell@$ipCell -H $ipPbx -f "$file"
    sleep 3
}

menu() {
    local error_msg=""

    while :; do
        clear

        if [ "" != "$error_msg" ]; then
            error "${error_msg}"
        fi

        echo -e "${green}***********************************${reset}"
        echo -e "${blue}Select the task:"
        echo -e "  1) Create a new cell Snom M900"
        echo -e "  2) Reprovision an existing M900"
        echo -e "  0) Exit"
        echo -e "${green}***********************************${reset}"

        read n
        case $n in
        1) create ;;
        2) execute ;;
        0) exit 1 ;;
        *) error_msg="Invalid option" ;;
        esac
    done
}

# Start script

if ! [ -x "$(command -v sipsak)" ]; then
    fail "\nError: sipsak is not installed!\n"
fi

# collect command line options

# default values for getopts
DIRECTORY="."

while getopts ":d:h" options; do
    case "${options}" in #
    d)
        DIRECTORY=${OPTARG}
        if ! [ -d "${DIRECTORY}" ]; then
            fail "\nDirectory '${DIRECTORY}' does not exist\n"
        fi
        ;;
    :)
        fail "Error: -${OPTARG} requires an argument."
        ;;
    h)
        usage
        ;;
    *)
        usage
        ;;
    esac
done

# add a / to the and of the directory if not present
DIRECTORY="$(echo ${DIRECTORY} | sed 's![^/]$!&/!')"

# start menu
menu
