#!/usr/bin/env bash
#==============================================================================
#Title           :batch_deploy_config_http.sh
#Description     :This script will deploy in bash configuration on Sonoff devices.
#Author          :Mickael Gaillard <mick.gaillard@gmail.com>
#Date            :20200323
#Version         :0.1
#Usage           :bash batch_deploy_config_http.sh
#==============================================================================

# Global options.
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
# set -o xtrace

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Set initial values.
FILE_CONFIG=deploy.config
FILE_CSV=hosts.csv
SEPARATOR=','

if [ -f ${script_dir}/$FILE_CSV ]; then
    # Read file...
    TAS_MAC=( $(cut -d $SEPARATOR -f1 $FILE_CSV ) )
    TAS_NAME=( $(cut -d $SEPARATOR -f2 $FILE_CSV ) )
    TAS_TYPE=( $(cut -d $SEPARATOR -f3 $FILE_CSV ) )
    TAS_ROOM=( $(cut -d $SEPARATOR -f4 $FILE_CSV ) )
    TAS_SAVE=( $(cut -d $SEPARATOR -f5 $FILE_CSV ) )

    #Scan network...
    HOSTS=$(sudo arp-scan -lNqxg |awk '{print $1"-"$2}')

    for HOST in $HOSTS; do

        IFS='-' read IP_DEV MAC <<<$HOST

        #echo ""
        #echo $IP_DEV
        #echo $MAC

        if [[ " ${TAS_MAC[@]} " =~ " ${MAC} " ]]; then

            index=-1
            for pos in ${!TAS_MAC[@]}; do
                #echo ${TAS_MAC[$pos]}
                if [[ "${TAS_MAC[$pos]}" = "${MAC}" ]]; then
                    index=$pos;
                fi
            done
            #echo $index

            # Set Config variable...
            DEVICE_NAME=${TAS_NAME[$index]}
            DEVICE_TYPE=${TAS_TYPE[$index]}
            DEVICE_ROOM=${TAS_ROOM[$index]}

            SAVE_SATE=0
            POWERONSTATE=1
            if [ ${TAS_SAVE[$index]} -eq 1 ]; then
                SAVE_SATE=1
                POWERONSTATE=3
            fi

            # Change on config file...
            sed -i "s/IP_DEV=.*/IP_DEV=$IP_DEV/" $FILE_CONFIG
            sed -i "s/DEVICE_NAME=.*/DEVICE_NAME=$DEVICE_NAME/" $FILE_CONFIG
            sed -i "s/DEVICE_TYPE=.*/DEVICE_TYPE=$DEVICE_TYPE/" $FILE_CONFIG
            sed -i "s/DEVICE_ROOM=.*/DEVICE_ROOM=$DEVICE_ROOM/" $FILE_CONFIG
            sed -i "s/SAVE_SATE=.*/SAVE_SATE=$SAVE_SATE/" $FILE_CONFIG
            sed -i "s/POWERONSTATE=.*/POWERONSTATE=$POWERONSTATE/" $FILE_CONFIG

            # Invoke deploy script...
            echo "call script ! $DEVICE_ROOM/$DEVICE_TYPE/$DEVICE_NAME ($SAVE_SATE/$POWERONSTATE)=> ${MAC}"
            /usr/bin/env bash deploy_config_http.sh
        fi
    done
fi
