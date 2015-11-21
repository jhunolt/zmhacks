#!/bin/bash
zmdbuser=`cat /etc/zm.conf | grep ZM_DB_USER | awk -F= '{print $2}' | tr -d ' '`
zmdbpass=`cat /etc/zm.conf | grep ZM_DB_PASS | awk -F= '{print $2}' | tr -d ' '`
runstate=`mysql -N -B -u$zmdbuser -p$zmdbpass zm -e "select Name  from States where isActive=1 LIMIT 1;"`

if [ "$runstate" != "vacation" ] 
then
	/usr/local/bin/arc_zm_log.pl "I've been requested to change to $1 - OK"
	echo "Change State Notification:$1" | /usr/bin/mail -s "ZoneMinder:Change State $1 Notification " user@gmail.com
	/usr/local/bin/zmpkg.pl $1;
	
else
	/usr/local/bin/arc_zm_log.pl "You are in Vacation mode, Ignoring request to change to $1"
fi
