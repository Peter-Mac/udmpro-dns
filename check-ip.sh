#!/usr/bin/env bash

#
# This script verifies the current external ip address of the UDM Pro unit against the
# previously identified value and if the address has changed since last run, makes a 
# callout to an update dns script.
#
# The script relies on a configuratin file (check-ip.conf) for preferences.
#
# A cron job containing schedule/frequency is used to control execution with a high
# frequency preferred to ensure any outages (change of Ip and internal service breaks)
# are identified quickly.
#
# An alternate approach is to run the update-dns scripts more frequently but that would
# create a network / bandwidth cost for the continuous updating of dns entries that don't 
# need to be changed. This approach is a happy medium (check ip change and only perform a
# dns update when an actual change has been identified.
#
# Notifications also sent via telegram to the MacMansion bot

###  Create check-ip.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/check-ip.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/check-ip.log'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

### Validate if config-file exists

if [[ -z "$1" ]]; then
  if ! source ${parent_path}/check-ip.conf; then
    echo 'Error! Missing configuration file check-.conf or invalid syntax!'
    exit 0
  fi
else
  if ! source ${parent_path}/"$1"; then
    echo 'Error! Missing configuration file '$1' or invalid syntax!'
    exit 0
  fi
fi

ipfile='/tmp/previous_ip'

ip=$(host myip.opendns.com resolver1.opendns.com |
    sed -n '/.* has address \(.*\)/ { s//\1/; p; q; }' )

if ! [[ -f $ipfile ]]; then
    echo "$ip" > "$ipfile"
fi

read -r previp < "$ipfile"
echo "Previous IP {$previp}, current IP {$ip}">>$LOG_FILE
if [[ $previp != "$ip" ]]; then
    msg="$(date): UDM Pro - IP address change from '$previp' to '$ip'"
    echo "$msg" >> $LOG_FILE

    ### Telegram notification
    if [ ${notify_me_telegram} == "no" ]; then
      exit 0
    fi

    if [ ${notify_me_telegram} == "yes" ]; then
      telegram_notification=$(
        curl -s -X GET "https://api.telegram.org/bot${telegram_bot_API_Token}/sendMessage?chat_id=${telegram_chat_id}" --data-urlencode "text=${msg}"
    )
      if [[ ${telegram_notification=} == *"\"ok\":false"* ]]; then
        echo ${telegram_notification=}
        echo "Error! Telegram notification failed" >> $LOG_FILE
        exit 0
      fi
    fi
 
    echo "$ip" > "$ipfile"

    ### Verify if we have to call the update-cloudflare-dns script
    if [ ${update_dns} == "yes" ]; then
        "./update-cloudflare-dns.sh"
    fi
fi  
