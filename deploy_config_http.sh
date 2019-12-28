#!/usr/bin/env bash
#==============================================================================
#Title           :deploy_config_http.sh
#Description     :This script will deploy configuration on Sonoff device.
#Author          :Mickael Gaillard <mick.gaillard@gmail.com>
#Date            :20191103
#Version         :0.1
#Usage           :bash deploy_config_http.sh
#==============================================================================

# Global options.
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
# set -o xtrace

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

# Set initial values.
IP_DEV=IP

DEVICE_DOMAIN=domain
DEVICE_NAME=device
DEVICE_TYPE=light
DEVICE_ROOM=room
DEVICE_USER=
DEVICE_PASS=

# Save state and aplly after reboot
SAVE_SATE=1

# Not add unit on result value
NO_UNIT=0

# Display value on Fahrenheit (or Celsius)
UNIT_FAR=0

DISPLAY_ENABLE=1

## DEFINE MANUALY ! (NOT USE FROM DHCP)
NTP_SRV1=pool.ntp.org
NTP_SRV2=0

## SERIAL CONFIG
SER_BAUD=9600

## MQTT
MQTT_ENABLE=1
MQTT_HOST=0
MQTT_PORT=1883
MQTT_USER=guest
MQTT_PASS=guest
MQTT_CLIENT=DVES_%06X
MQTT_GRP=all
MQTT_TOPIC="$DEVICE_NAME"
MQTT_FULLTOPIC="home/$DEVICE_ROOM/$DEVICE_TYPE/%topic%/%prefix%/"
MQTT_PREFIX_CMD=cmd
MQTT_PREFIX_STA=state
MQTT_MSG_OFF=OFF
MQTT_MSG_ON=ON
MQTT_MSG_TOGGLE=TOGGLE
MQTT_MSG_HOLD=HOLD

# Internal functions

help() {
  echo -e "\nbash deploy_config_http.sh [opt1] [opt1] [...]"
  echo "Options :"
  echo -e " -h | --help\t\t\t: this help message."
  echo -e "\neg. : bash deploy_config_http.sh"
  echo -e "\nOR You can config all options in deploy.config file."
}

readFile() {
  # Read config from file.
  if [ -f ${script_dir}/deploy.config ]; then
    echo "Read config from file..."
    . ${script_dir}/deploy.config
  fi
}

readFile


DEVICE_FULLNAME="$DEVICE_NAME-$DEVICE_TYPE.$DEVICE_ROOM"
DEVICE_HOSTNAME="$DEVICE_NAME-$DEVICE_TYPE.$DEVICE_ROOM" # Replace "%s-%04d"

## https://github.com/arendst/Sonoff-Tasmota/wiki/Commands
ACTIONS_NO_REBOOT="\
 SetOption0 $SAVE_SATE;\
 SetOption3 $MQTT_ENABLE;\
 SetOption8 $UNIT_FAR;\
 SetOption53 $DISPLAY_ENABLE;\
 StateText1 $MQTT_MSG_OFF;\
 StateText2 $MQTT_MSG_ON;\
 StateText3 $MQTT_MSG_TOGGLE;\
 StateText4 $MQTT_MSG_HOLD;\
 PowerOnState $POWERONSTATE;\
 IPAddress1 0.0.0.0;\
 FriendlyName $DEVICE_FULLNAME;\
 Hostname $DEVICE_HOSTNAME;\
 WebPassword $DEVICE_PASS;\
 WifiConfig 4;\
"
# REMOVE COMMAND
#  SetOption2 $NO_UNIT;\

ACTIONS_WITH_REBOOT="\
 MqttClient $MQTT_CLIENT;\
 MqttHost $MQTT_HOST;\
 MqttPort $MQTT_PORT;\
 MqttUser $MQTT_USER;\
 MqttPassword $MQTT_PASS;\
 Prefix1 $MQTT_PREFIX_CMD;\
 Prefix2 $MQTT_PREFIX_STA;\
 Topic $MQTT_TOPIC;\
 GroupTopic $MQTT_GRP;\
 FullTopic $MQTT_FULLTOPIC;\
 NtpServer1 $NTP_SRV1;\
 NtpServer2 $NTP_SRV2;\
 NtpServer3 0;\
 BlinkCount 2;\
 Power1 Blink;\
 restart 1
"

#ACTIONS="$ACTIONS_NO_REBOOT" #$ACTIONS_WITH_REBOOT"
# Baudrate $SER_BAUD;\

send_cmd() {
        # DISPLAY OPTIONS
        ACTIONS=$1
        DISPLAY_ACTION=$( printf "%s\n" "$ACTIONS" | sed 's/;/\\n/g' )  # Encode space
        echo "Config Options :\n$DISPLAY_ACTION\n"

        # MAKE CALL (URL ENCODE)
        ACTIONS=$( printf "%s\n" "$ACTIONS" | sed 's/\%/%25/g' ) # Encode %
        ACTIONS=$( printf "%s\n" "$ACTIONS" | sed 's/\//%2F/g' ) # Encode /

        URL="http://$IP_DEV/cm?user=$DEVICE_USER&password=$DEVICE_PASS&cmnd=Backlog$ACTIONS"
        URL=$( printf "%s\n" "$URL" | sed 's/ /%20/g' )  # Encode space
        URL=$( printf "%s\n" "$URL" | sed 's/;/%3B/g' )  # Encode space

        echo "Debug URL (do not click):\n$URL\n"
        curl $URL
}

send_cmd "$ACTIONS_NO_REBOOT"

send_cmd "$ACTIONS_WITH_REBOOT"


echo "\n\nDevice is reboot ! please wait...\n"
/bin/sleep 3
echo "Now connect to : http://$IP_DEV"

