#! /usr/bin/env python
import sys

import csv

start_time=-1
end_time=-1
interval=-1
lines=0

debug=0
#print sys.argv[1]
decimate_to=int(float(sys.argv[1])*1000)
#print type(decimate_to)
sys.stdout.write ("Decimate to: " + str(decimate_to) + "\n")

Reader=csv.reader(sys.stdin)
Writer=csv.writer(sys.stdout)

if decimate_to == 0 :
    for row in Reader:
        lines+=1
        if (lines<4):
            continue

        Writer.writerow(row)
    
else:
    for row in Reader:
        lines+=1
        if (lines<4):
            print row
            continue

        time=int(float(row[1])*1000)
        if time % decimate_to == 0 :
            Writer.writerow(row)
    
