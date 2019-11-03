#!/bin/sh

USB=/dev/ttyUSB0
FILE_FW=sonoff.bin
SIZE_FLASH=1MB
CMD=esptool

echo "GET MAC (for filename)...\n"
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
