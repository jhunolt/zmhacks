#!/bin/bash
runstate=`cat /usr/share/zoneminder/zm_run_state.txt`
if [ "$runstate" != "vacation" ];
then
	/usr/bin/arc_zm_log.pl "ARC:I've been requested to change to $1 - OK"
	/usr/bin/zmpkg.pl $1;
else
	/usr/bin/arc_zm_log.pl "ARC:You are in Vacation, Ignoring request to change to $1"
fi
