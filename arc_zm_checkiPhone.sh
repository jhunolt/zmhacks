#!/bin/bash
# checks to see if iPhone is out, but ZM is in 
# cron will schedule this 
# also checks if you are in and ZM thinks you are out
# So basically, your phone has the power to override ZM's schedule
# Given we are always where our phone is, unless you lost it, or forgot it
# this is mostly the right state to be in (aka your phone = your presence)
   

filepath="/usr/local/share/zoneminder"

zmdbuser=`cat /etc/zm.conf | grep ZM_DB_USER | awk -F= '{print $2}' | tr -d ' '`
zmdbpass=`cat /etc/zm.conf | grep ZM_DB_PASS | awk -F= '{print $2}' | tr -d ' '`

runstate=`mysql -N -B -u$zmdbuser -p$zmdbpass zm -e "select Name  from States where isActive=1 LIMIT 1;"`
iphonestate=`cat $filepath/zm_phone_state.txt`
control="/usr/local/bin/arc_zm_change_state.sh"
zmlog="/usr/bin/arc_zm_log.pl"
nowdate=`date`


if [ "$runstate" = "in-modect" ] && [ "$iphonestate" = "out" ]; then
	$zmlog "ARC:Oops looks like you stepped out and ZM is not aware!"
	$control out-modect
	echo "Changed to out-modect at $nowdate - your phone is out" | /usr/bin/mail -s "ZoneMinder:Changed state to out-modect" arjunrc@gmail.com	

elif [ "$runstate" = "out-modect" ] && [ "$iphonestate" = "in" ]; then
	$zmlog "Hey, ZM thinks you are out, but your phone says you are in"
	$control in-modect
	echo "Changed to in-modect at $nowdate - your phone is in" | /usr/bin/mail -s "ZoneMinder:Changed state to in-modect" arjunrc@gmail.com	

#else
	#echo "No need to change state: Your phone says $iphonestate and ZM is in $runstate" >> $filepath/$logfile
#	$zmlog "No need to change state: Your phone says $iphonestate and ZM is in $runstate"

fi
