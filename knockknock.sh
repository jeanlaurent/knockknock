#!/bin/sh
ip=`ifconfig | awk '/inet /' | awk '!/127.0./' | awk '!/172./' | awk '{ print $2 }'`
subnet=`echo $ip | cut -d '.' -f1-3`
# echo "$subnet.*"
sudo arp-scan -l | grep "$subnet" |  awk '{print $1,$2}' | tr '[:lower:]' '[:upper:]'
# sudo nmap -sP $subnet.1-254 | grep MAC |  awk '{print $3}'
