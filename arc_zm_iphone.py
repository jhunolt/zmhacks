#!/usr/bin/python
from pyicloud import PyiCloudService
from geopy.distance import vincenty
import geopy.exc
import sys
import time
import os

my_name="xxxxx@gmail.com" # icloud user name
my_password="xxxx"	    # icloud main password. PyiCloud is webscraper - so app specific won't work


home = (1111,-11111111) 	 # add your lat/long for your hose
mindist = 0.1			 # in miles. The distance between your home lat/long and where you are.
				 # if the difference between your phone location and home location is more
				 # than mindist, I will assume your phone is 'out of the house'

				 # returns and then use an appropriate substring
my_dev_name="xxxx"		 # your device name. Uncomment the print dev line below to see all the device names and
				 # pick the one that corresponds to your iPhone

# If you are home, this file will contain the word 'in', otherwise it will contain 'out'
# Now, you can easily use this file and change run states to start recording with ZM. Cool,huh?
my_out_file="/usr/share/zoneminder/zm_phone_state.txt"
my_out_log_file="/usr/share/zoneminder/zm_phone_state_log.txt"

f=open("/usr/share/zoneminder/zm_run_state.txt","r")
flog=open(my_out_log_file,"w")
flog.write ("Phone Check log: " + time.strftime("%c") + "\n")


api = PyiCloudService(my_name, my_password)
for rdev in  api.devices:
	dev = str(rdev)
	flog.write("Iterating device:%s\n" % dev);
	if my_dev_name in dev:
		flog.write("--- %s matches %s\n" % (dev,my_dev_name))
		# wait for location till it is fresh
		while rdev.location()['locationFinished'] !=True:
			flog.write("Iterating location, as it is not fresh\n")
			pass
		latitude = float(rdev.location()['latitude'])
		longitude = float(rdev.location()['longitude'])
		current = (latitude,longitude)
		dist = vincenty(home,current).miles

		flog.write ("---location reported:lat:%f long:%f\n" % (latitude,longitude))
		flog.write ("----distance between points is %f\n" % dist)
		if dist <= mindist:
			phone_state="in"
		else:
			phone_state="out"
		f = open (my_out_file,'w')
		f.write(phone_state)
		#flog.write ("Got location as %s\n" % location[0])
		flog.write ("Writing phone state as %s\n" % phone_state)
		f.close()
		flog.close()
		os.system('/bin/cat /usr/share/zoneminder/zm_phone_state_log.txt | /usr/bin/mail -s "ZoneMinder: Phone check status" user@gmail.com');
		sys.exit()
# if we come here, dev was not found, that's odd
flog.write("Hmm, looks like I did not find your device?\n");
flog.close()

		
