#!/usr/bin/env python3

#import fileinput
import pprint
import sys
import csv
from JCMBSoftPyLib import GPS_TIME

writer = csv.writer(sys.stdout)

line_num=0

for line in sys.stdin:
#   print line
#   if fileinput.isfirstline() :
#       if fileinput.isstdin() :
#           print "Processing: Standard Input"
#       else :
#           print "Processing:",fileinput.filename()
   line_num+=1
#   print line_num
   if line_num <= 4:
      continue
   line=line.rstrip()
   line=line.replace(" ","")
   line=line.replace("Nan","")
   fields=line.split(",")

   if len(fields) < 3 :
      continue
   try :
#       print "Fields 1"
       n_fields=int(fields[2])
       Time=GPS_TIME.Week_Seconds_To_Unix(int(fields[0]),float(fields[1]))
#       print "Fields 2"
       output_fields=[None]*30
       output_fields[0]=Time
#       print n_fields
#       print output_fields
#       print "Fields 3"

       for field in range(n_fields):
#            print field
#            print "ID"
#            print fields[3+2*field]
#            print "VALUE"
#            print fields[4+2*field]
            field_id=int(fields[3+2*field])
            field_value=fields[4+2*field]
#            print field_id,field_value
            output_fields[field_id]=field_value
#            print output_fields

#       print "Fields 4"
       if output_fields[1] or output_fields[2] or output_fields[3] :
          writer.writerow(output_fields	)
          #Only write a line if there is a voltage 
#       print output_fields
   except :
#      print "Got Exception"
      continue
