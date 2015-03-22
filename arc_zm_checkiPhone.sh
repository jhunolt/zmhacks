#!/bin/bash
# checks to see if iPhone is out, but ZM is in 
# cron will schedule this 
# also checks if you are in and ZM thinks you are out
# So basically, your phone has the power to override ZM's schedule
# Given we are always where our phone is, unless you lost it, or forgot it
# this is mostly the right state to be in (aka your phone = your presence)

filepath="/usr/share/zoneminder"
logfile="zm_phone_state_log_cron.txt"
runstate=`cat $filepath/zm_run_state.txt`
iphonestate=`cat $filepath/zm_phone_state.txt`
control="/usr/bin/arc_zm_change_state.sh"
zmlog="/usr/bin/arc_zm_log.pl"


echo `date` > $filepath/$logfile

if [ "$runstate" = "in-modect" ] && [ "$iphonestate" = "out" ]; then
	echo "Oops looks like you stepped out and ZM is not aware!" >> $filepath/$logfile
	$zmlog "ARC:Oops looks like you stepped out and ZM is not aware!"
	$control out-modect
elif [ "$runstate" = "out-modect" ] && [ "$iphonestate" = "in" ]; then
	echo "ARC:Hey, ZM thinks you are out, but your phone says you are in" >> $filepath/$logfile
	$zmlog "Hey, ZM thinks you are out, but your phone says you are in"
	$control in-modect

else
	echo "No need to change state: Your phone says $iphonestate and ZM is in $runstate" >> $filepath/$logfile
#	$zmlog "No need to change state: Your phone says $iphonestate and ZM is in $runstate"

fi
