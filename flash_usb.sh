#!/usr/bin/env bash
#==============================================================================
#Title           :flash_usb.sh
#Description     :This script will flash Sonoff device with custom firmware.
#Author          :Mickael Gaillard <mick.gaillard@gmail.com>
#Date            :20191103
#Version         :0.1
#Usage           :bash flash_usb.sh --usb /dev/ttyUSB0 --file sonoff.bin
#==============================================================================

set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
# set -o xtrace

readonly script_name=$(basename "${0}")
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

# set initial values.
VERBOSE=false
USB=/dev/ttyUSB0
FILE_FW=sonoff.bin
SIZE_FLASH=1MB
CMD=esptool

parse() {
# Option strings.
  SHORT=vu:f:s:c:
  LONG=verbose,usb:,file:,size:,cmd:

  # read the options.
  OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")
  if [ $? != 0 ] ; then echo "Failed to parse options...exiting." >&2 ; exit 1 ; fi
  eval set -- "$OPTS"

  # extract options and their arguments into variables.
  while true ; do
    case "$1" in
      -v | --verbose )
        VERBOSE=true
        shift
        ;;
      -u | --usb )
        USB="$2"
        shift 2
        ;;
      -f | --file )
        FILE_FW="$2"
        shift 2
        ;;
      -s | --size )
        SIZE_FLASH="$2"
        shift 2
        ;;
      -c | --cmd )
        CMD="$2"
        shift 2
        ;;
      -- )
        shift
        break
        ;;
      *)
        echo "Internal error!"
        exit 1
        ;;
    esac
  done

  # check variables.
  if [ ! -e "$USB" ]; then
    echo "Error: USB at ${USB} not found" >&2
    exit 1
  fi

  if [ ! -e "$FILE_FW" ]; then
    echo "Error: Firmware ${FILE_FW} not found" >&2
    exit 1
  fi

  if ! [ -x "$(command -v "$CMD")" ]; then
    echo "Error: ${CMD} is not installed or found." >&2
    exit 1
  fi
}

main() {
  echo -e "GET MAC (for filename)...\n"
  MAC=$($CMD -p $USB flash_id | grep -oE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
  FILE="logs/$MAC.txt"

  echo "" >> $FILE
  date +"%e/%m/%Y %H:%M:$S %Z" >> $FILE
  echo "" >> $FILE

  echo "\nGET FLASH...\n" | tee -a $FILE
  $CMD -p $USB flash_id | tee -a $FILE
  echo "" >> $FILE


  echo "\nFLASHING...\n" | tee -a $FILE
  $CMD -p $USB write_flash -fs $SIZE_FLASH -fm dout 0x0 $FILE_FW | tee -a $FILE
  echo "" >> $FILE


  echo "\ndone !\n"
  echo "====================================" >> $FILE
}

parse "${@}"
main
