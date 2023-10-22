#!/bin/bash

set -e

trap 'if [ $? -eq 0 ]; then echo -e "\nWifi completed without errors"; else echo -e "\nWifi did NOT complete correctly"; fi' EXIT

rfkill unblock 0
rfkill unblock 1

read -p "Enter SSID Name: " SSIDNAME
read -s -p "Enter SSID Password: " SSIDPW	
iwctl --passphrase=$SSIDPW station wlan0 connect $SSIDNAME
