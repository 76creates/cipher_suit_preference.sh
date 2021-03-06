#!/bin/bash

host=$1

if [[ -z $2 ]]
then 
    port=443
else 
    port=$2
fi

cipher_list=":"$(openssl ciphers)":"

function get_prefered() {
    # $1 > protocol version
    # $2 > cipher
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -n | timeout -s SIGTERM -k 5s 3s openssl s_client -$1 -cipher $2 -connect $host:$port 2>&1 | grep "Cipher    :" | cut -d" " -f 10
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # brew install coreutils
        echo -n | gtimeout -s SIGTERM -k 5s 3s openssl s_client -$1 -cipher $2 -connect $host:$port 2>&1 | grep "Cipher    :" | cut -d" " -f 10
    else 
        #unknown os
        echo "unknown OS"
        exit 1
    fi
}

echo "Cipher suit preference list"

for protocol in ssl3 tls1 tls1_1 tls1_2
do
    temp_list=$cipher_list
    first_preference=$(get_prefered $protocol "$temp_list")
    declare -a pref_$protocol
    case $first_preference in
        0000) echo -e "\033[1m$protocol\033[0m not supported"; continue;;
        
        "") echo -e "\033[1m$protocol\033[0m not supported"; continue;;
        
        *)echo -e "\033[1m$protocol\033[0m"
            echo -e "\t$first_preference"
            temp_list=$(echo $temp_list | sed -e "s/\:$first_preference\:/\:/");;
    esac
    while true
    do
        next_preference=$(get_prefered $protocol "$temp_list")
        case $next_preference in
            0000) break ;;
            *)echo -e "\t$next_preference"
                temp_list=$(echo $temp_list | sed -e "s/\:$next_preference\:/\:/");;
        esac
    done

done
