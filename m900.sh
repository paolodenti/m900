#-----------------------
# Script to refresh configuration for Snom M900
#
# you need to install sipsak
# 
#-----------------------

#!/bin/bash

# Ansi color code variables
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

if ! [ -x "$(command -v sipsak)" ]; then
  echo "\n"
  echo "Error: sipsak is not installed! \n" >&2
  exit 1
fi

# the create function add a file with m900 extension with parameter to send with sipsak

create(){
echo "Please give me a name without spaces"
read name
echo "the name is" $name "\n"

echo "Please give me the multicell id"
read id
echo "the id is" $id "\n"

echo "Please give me the M900 IP"
read m900Ip
echo "the m900 ip is" $m900Ip "\n"

echo "Please give me the PBX IP"
read pbxIp
echo "the 3cx ip is" $pbxIp "\n"

tee $name.m900 <<EOF
NOTIFY sip:$id@$m900Ip SIP/2.0
To: sip:$id@$m900Ip
From: sip:sipsak@$pbxIp
CSeq: 10 NOTIFY
Call-ID: 1234@$pbxIp
Event: check-sync;reboot=false
EOF

echo "\n"
echo "File created successfully \n" 
sleep 3
menu
}

# the execute function permit to select cell to provision

execute(){
if [ -f *.m900 ]; then

    echo "Please select the M900 name"
    set -- *.m900

    while true; do
        i=0
        for pathname do
            i=$(( i + 1 ))
            printf '%d) %s\n' "$i" "$pathname" >&2
        done

        printf 'Select m900 cell, or 0 to exit: ' >&2
        read -r reply

        number=$(printf '%s\n' "$reply" | tr -dc '[:digit:]')

        if [ "$number" = "0" ]; then
            echo 'Bye!' >&2
            exit
        elif [ "$number" -gt "$#" ]; then
            echo 'Invalid choice, try again' >&2
        else
            break
        fi
    done

    shift "$(( number - 1 ))"
    file=$1

    provisioning

else 
    printf "${red}No cell configured. \n"
    printf "Please create a new cell first!${reset} \n"
    sleep 3
    menu
fi
}

# the provisioning function send command to the m900

provisioning(){
idCell=$(cat $file | awk -F"[:@]" '/To:/{print $3}')
ipCell=$(cat $file | awk -F"[:@]" '/To:/{print $4}')
ipPbx=$(cat $file | awk -F"[:@]" '/From:/{print $4}')

echo sipsak -vvv -G -s sip:$idCell@$ipCell -H $ipPbx -f $file
}

menu(){
clear
printf "${green}***********************************${reset}\n"
printf "${blue}Select the task:\n"
printf "  1)Create a new cell Snom M900 \n"
printf "  2)Reprovision an existing M900 \n"
printf "  0)Exit \n"
printf "${green}***********************************${reset}\n"

read n
case $n in
  1) create ;;
  2) execute ;;
  0) exit 1 ;;
  *) echo "${red}Invalid option${reset}";;
esac
sleep 2
menu
}


# Start script
menu