#!/usr/bin/python
from pyicloud import PyiCloudService
from geopy.distance import vincenty
import geopy.exc
import sys
import time
import os

my_name="xxxxx@gmail.com" # icloud user name
my_password="xxxxx"	    # icloud main password. PyiCloud is webscraper - so app specific won't work


home = (11.111111,-11.111111)    # lat long for your home - put it in here
mindist = 0.1			 # in miles. The distance between your home lat/long and where you are.
				 # if the difference between your phone location and home location is more
				 # than mindist, I will assume your phone is 'out of the house'

				 # returns and then use an appropriate substring
my_dev_name="XXXXXX iPhone 5S"	 # your device name. Uncomment the print dev line below to see all the device names and
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

		# for some odd ball reason, this locationFinished stuff does not work
		# what I've found works well is seek location, snooze for a minute
		# then seek again and then check for the finished flag
		curr_loc = rdev.location()
		curr_loc_set = (curr_loc['latitude'],curr_loc['longitude'])
		dist = vincenty(home,curr_loc_set).miles
		flog.write ("I got location as: (lat) %f, (long) %f, Finished:%d, Distance:%f miles\n" 
		% (curr_loc['latitude'], curr_loc['longitude'],curr_loc['locationFinished'],dist))
		flog.write ("Sleeping for 60 seconds to make sure its fresh...\n")
		time.sleep(60)
		curr_loc = rdev.location()
		curr_loc_set = (curr_loc['latitude'],curr_loc['longitude'])
		dist = vincenty(home,curr_loc_set).miles
		flog.write ("AFTER SLEEP OF 60S: I got location as: (lat) %f, (long) %f, Finished:%d, Distance:%f miles\n" \
		% (curr_loc['latitude'], curr_loc['longitude'],curr_loc['locationFinished'],dist))

		while curr_loc['locationFinished'] !=True:
			flog.write("Iterating location, as it is not fresh.Sleeping for additional 5 secs\n")
			time.sleep(5)
			curr_loc = rdev.location()
			pass
		latitude = float(curr_loc['latitude'])
		longitude = float(curr_loc['longitude'])
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
		os.system('/bin/cat /usr/share/zoneminder/zm_phone_state_log.txt | /usr/bin/mail -s "ZoneMinder: Phone check status" arjunrc@gmail.com');
		sys.exit()
# if we come here, dev was not found, that's odd
flog.write("Hmm, looks like I did not find your device?\n");
flog.close()

		
