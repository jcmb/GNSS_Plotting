#!/usr/bin/env python3

#import fileinput
import pprint
import sys
import csv
import GPS_TIME

from gnss_time import gps_week_sow_to_gps_unix

writer = csv.writer(sys.stdout)

for line in sys.stdin:
#   if fileinput.isfirstline() :
#       if fileinput.isstdin() :
#           print "Processing: Standard Input"
#       else :
#           print "Processing:",fileinput.filename()
   line=line.rstrip()
   line=line.replace(" ","")
   line=line.replace("Nan","")
   fields=line.split(",")
   if len(fields) < 71 :
      continue
   try :
       fields[1]=gps_week_sow_to_gps_unix(int(fields[0]),float(fields[1]))
       fields[0]=""
       writer.writerow(fields[:29])
#       print fields
   except :
      continue

