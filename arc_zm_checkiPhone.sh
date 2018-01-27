#!/bin/bash
# checks to see if iPhone is out, but ZM is in 
# cron will schedule this 
# also checks if you are in and ZM thinks you are out
# So basically, your phone has the power to override ZM's schedule
# Given we are always where our phone is, unless you lost it, or forgot it
# this is mostly the right state to be in (aka your phone = your presence)
   

filepath="/usr/share/zoneminder"

zmdbuser=`cat /etc/zm/zm.conf | grep ZM_DB_USER | awk -F= '{print $2}' | tr -d ' '`
zmdbpass=`cat /etc/zm/zm.conf | grep ZM_DB_PASS | awk -F= '{print $2}' | tr -d ' '`
runstate=`mysql -N -B -u$zmdbuser -p$zmdbpass zm -e "select Name  from States where isActive=1 LIMIT 1;"`
control="/usr/local/bin/arc_zm_change_state.sh"
zmlog="/usr/local/bin/arc_zm_log.pl"
nowdate=`date`
file_changestate="zm_change_state.txt"
file_phonestate="zm_phone_state.txt"

if [ ! -e "$filepath/$file_phonestate" ]; then
	$zmlog "creating $file_phonestate";
	echo "out" > "$filepath/$file_phonestate";
fi

if [ ! -e "$filepath/$file_changestate" ]; then
	$zmlog "creating $file_changestate";
	echo "1" > "$filepath/$file_changestate";
fi


iphonestate=`cat $filepath/$file_phonestate`
switchstate=`cat $filepath/$file_changestate`

if [ "$switchstate" = "0" ]; then
	$zmlog "ARC: Not switching state, as $filepath/$filechangestate is 0";
	exit;
fi



if [ "$runstate" = "in-modect" ] && [ "$iphonestate" = "out" ]; then
	$zmlog "Oops looks like you stepped out and ZM is not aware!"
	$control out-modect
	

elif [ "$runstate" = "out-modect" ] && [ "$iphonestate" = "in" ]; then
	$zmlog "Hey, ZM thinks you are out, but your phone says you are in"
	$control in-modect
	

#else
	#echo "No need to change state: Your phone says $iphonestate and ZM is in $runstate" >> $filepath/$logfile
#	$zmlog "No need to change state: Your phone says $iphonestate and ZM is in $runstate"

fi
