#!/usr/bin/env python

import sys
import csv
import os

start_time=-1
end_time=-1
interval=-1
lines=0

debug=1

#print sys.argv[1]
if os.path.isfile(sys.argv[1]):
   X29=open(sys.argv[1], 'r')
   sys.stderr.write("Compute_decimate of file\n")
   sys.stderr.write(sys.argv[1]+"\n")
else:
   sys.stderr.write("Parameter to compute_decimate is not a file\n")
   sys.stderr.write(sys.argv[1]+"\n")
   quit(2)

Reader=csv.reader(X29)
for row in Reader:
#    print row
    lines+=1

    if (lines<5):
        continue

    time=float(row[1])
#    print time

    if ( start_time == -1 ) :
        start_time=time
    else :
        if ((interval==-1) and (time != start_time)):
            interval= time-start_time

    if row[1]<start_time:
        end_time=time+604800
    else:
        end_time=time
X29.close()

epochs=((end_time-start_time)/interval)+1
#print interval
interval=int(interval*1000+0.5)
#print interval
interval=float(interval)/1000
#print interval

if (debug) :
    sys.stderr.write(str(start_time))
    sys.stderr.write("\n")
    sys.stderr.write(str(end_time))
    sys.stderr.write("\n")
    sys.stderr.write(str(interval))
    sys.stderr.write("\n")
    sys.stderr.write(str(epochs))
    sys.stderr.write("\n")

if epochs < 1000:
   decimate_to = 0 
elif epochs < 2000:
   decimate_to = 2 * interval
elif epochs < 3000:
   decimate_to = 3 * interval
elif epochs < 4000:
   decimate_to = 4 * interval
elif epochs < 5000:
   decimate_to = 5 * interval
elif epochs < 10000:
   decimate_to = 10 * interval
elif epochs < 20000:
   decimate_to = 20 * interval
elif epochs < 30000:
   decimate_to = 30 * interval
elif epochs < 40000:
   decimate_to = 40 * interval
elif epochs < 50000:
   decimate_to = 50 * interval
elif epochs < 60000:
   decimate_to = 60 * interval
elif epochs < 70000:
   decimate_to = 70 * interval
elif epochs < 80000:
   decimate_to = 80 * interval
elif epochs < 90000:
   decimate_to = 90 * interval
elif epochs < 100000:
   decimate_to = 100 * interval
elif epochs < 110000:
   decimate_to = 110 * interval
else:
   decimate_to = 120 * interval

sys.stderr.write(str(decimate_to))
sys.stderr.write("\n")
print "Decimate="+str(decimate_to)+"; interval="+str(interval)
