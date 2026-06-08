#!/usr/bin/env python
from __future__ import division

#import fileinput
import pprint
import sys
import csv
import os

if  (sys.version_info>=(2,7,0)):
    import argparse


    class ArgParser(argparse.ArgumentParser):

        def convert_arg_line_to_args(self, arg_line):
            for arg in arg_line.split():
                if not arg.strip():
                    continue
                yield arg

    parser = ArgParser(
                description='Compute Out of range measurements and time',
                fromfile_prefix_chars='@',
                epilog="(c) JCMBsoft 2015")

    parser.add_argument("-R", "--RANGE", type=float, default=0.0305, help="Report out of range if difference from the mean is more than this range, in m")
    parser.add_argument("-I", "--IN", type=float, default=5, help="Length of time that we have to be in range to say that the system has transisitioned to good ")
    parser.add_argument("-H", "--HEIGHT", type=float, default=0.0, help="Mean for the height, 0 default")
    parser.add_argument("-V", "--VERBOSE", action="store_true", help="Display, to StdErr, what is happening")
    parser.add_argument("-O", "--OUTAGES", dest="outage_filename",help="write report of outages to files OUTAGES", metavar="FILE")
    parser.add_argument("-S", "--SUMMARY", dest="summary_filename",help="Write summary report to file SUMMARY. Output to stderr otherwise", metavar="FILE")
    parser.add_argument("-D", "--DETAIL", dest="detail_filename",help="write report of details to files DETAIL. Output stdout otherwise", metavar="FILE")


    args=parser.parse_args()

else:
    from optparse import OptionParser

    parser = OptionParser()

    parser.add_option("-R", "--RANGE", type=float, default=0.0305, help="Report out of range if difference from the mean is more than this range, in m")
    parser.add_option("-I", "--IN", type=float, default=5, help="Length of time that we have to be in range to say that the system has transisitioned to good ")
    parser.add_option("-H", "--HEIGHT", type=float, default=0.0, help="Mean for the height, 0 default")
    parser.add_option("-V", "--VERBOSE", action="store_true", help="Display, to StdErr, what is happening")
    parser.add_option("-O", "--OUTAGES", dest="outage_filename",help="Write report of outages to file OUTAGES", metavar="FILE")
    parser.add_option("-S", "--SUMMARY", dest="summary_filename",help="Write summary report to file SUMMARY. Output to stderr otherwise", metavar="FILE")
    parser.add_option("-D", "--DETAIL", dest="detail_filename",help="Write report of details to files DETAIL. Output to stdout otherwise", metavar="FILE")

    (args,opts) = parser.parse_args()
#    print args
#    print opts
#    print args.RANGE
#    print args.HEIGHT
#    print args.VERBOSE

range=args.RANGE
in_range_time=args.IN
mean_height=args.HEIGHT
verbose=args.VERBOSE


if args.outage_filename:
    if verbose:
        sys.stderr.write("Outage File:  {0}\n".format(args.outage_filename))
    outage_file = open(args.outage_filename,"w")
else:
    if verbose:
        sys.stderr.write("Outage File:  {0}\n".format("Not created"))
    outage_file = open(os.devnull,"w")

if args.summary_filename:
    if verbose:
        sys.stderr.write("Summary File: {0}\n".format(args.summary_filename))
    summary_file = open(args.summary_filename,"w")
else:
    if verbose:
        sys.stderr.write("Summary File: {0}\n".format("Standard Error"))
    summary_file = sys.stderr

if args.detail_filename:
    if verbose:
        sys.stderr.write("Detail File:  {0}\n".format(args.detail_filename))
    detail_file = open(args.detail_filename,"w")
else:
    if verbose:
        sys.stderr.write("Detail File:  {0}\n".format("Standard Output"))
    detail_file = sys.stdout


total_epochs=0
above_epochs=0
below_epochs=0
above_with_range_epochs=0
below_with_range_epochs=0
in_range=0
max_outage=0

start_of_in_range=None

last_delta=0
event_start_time=None

first_epoch=None
second_epoch=None
epoch_interval=0 #We get wrong by an epoch if we are out of range for the first epoch

if verbose:
    sys.stderr.write("Height (m):            {0}\n".format(mean_height))

summary_file.write("Range (m) :            {0}\n".format(range))
summary_file.write("Hysteresis time (s)    {0}\n".format(in_range_time))


#writer = csv.writer(sys.stdout)
reader = csv.reader(sys.stdin)

stored_records=[]
stored_in_range_records=[]

def dump_stored_data(stored_records,last_delta):

    global max_outage

    if stored_records == []:
        return


    event_start_time=stored_records[0][0]
    time=stored_records[len(stored_records)-1][0]

    delta_time=time-event_start_time+epoch_interval

    max_error=0

    if delta_time>max_outage:
        max_outage=delta_time
    for record in stored_records:
        detail_file.write("{0},{1:0.3f},{2},{3:0.2f},{4:0.2f}\n".format(record[0],record[1],record[2],record[3],delta_time))
        if record[1] < 0:
            if record[1]< max_error:
                max_error=record[1]
        elif record[1]  > 0:
            if record[1] > max_error:
                max_error=record[1]


#    outage_file.write("{0},{1},{2}\n".format((time+event_start_time)/2,last_delta,delta_time))
    outage_file.write("{0},{1:0.3f},{2}\n".format((time+event_start_time)/2,max_error,delta_time))

def dump_stored_in_range_data(stored_records,):

    if stored_records == []:
        return


    for record in stored_records:
        detail_file.write("{0},{1:0.3f},{2},{3:0.2f},{4:0.2f}\n".format(record[0],0,0,0,0))


for row in reader:


    height=float(row[12])-mean_height
    time=float(row[1])
    total_epochs+=1

    if not first_epoch:
        first_epoch=time
#        outage_file.write("{0},{1:0.3f},{2}\n".format(time,0,0)) # Write the start time so we can scale the graph correctly
    elif not second_epoch:
        second_epoch=time
        epoch_interval=second_epoch-first_epoch
        summary_file.write("Epoch interval (s):    {0:0.2f}\n".format(epoch_interval))


#    print row
#    print "In Range list"
#    print stored_in_range_records
#    print "Stored"
#    print stored_records
    if height<-range:
#        print "Below"
        below_epochs+=1
        below_with_range_epochs+=1

        if len(stored_in_range_records)!=0:
            stored_records.extend(stored_in_range_records)
            stored_in_range_records=[]

        if last_delta != -1:
            dump_stored_data(stored_records,last_delta)
            stored_records=[]
            event_start_time=float(row[1])



        stored_records.append([time,height,-1,time-event_start_time+epoch_interval])
        #print "{0},{1:0.3f},{2},{3:0.2f}".format(row[1],height+range,-1,float(row[1])-event_start_time)
        last_delta=-1
        last_event_time=time
    elif height>range:
#        print "Above"
        above_epochs+=1
        above_with_range_epochs+=1

        if len(stored_in_range_records)!=0:
            stored_records.extend(stored_in_range_records)
            stored_in_range_records=[]

        if last_delta != 1:
            dump_stored_data(stored_records,last_delta)
            stored_records=[]
            event_start_time=float(row[1])
        stored_records.append([time,height,1,time-event_start_time+epoch_interval])
        last_event_time=time

#        print "{0},{1:0.3f},{2},{3:0.2f}".format(row[1],height-range,1,float(row[1])-event_start_time)
        last_delta=1
    else:
#        print "In Range"

#        if start_of_in_range:
#            print time,event_start_time, start_of_in_range, in_range_time, time-start_of_in_range ,(time-start_of_in_range>= in_range_time)
        # Here we have a value in range, we have to determine if we have had it long enough to call it OK though
        # We have to have at least
        in_range+=1
        if last_delta != 0:
            if stored_in_range_records==[]:
                start_of_in_range=time

            if last_delta == -1:
                below_with_range_epochs+=1
            else:
                above_with_range_epochs+=1

            if time-start_of_in_range>= in_range_time:
                dump_stored_data(stored_records,last_delta)
                dump_stored_in_range_data(stored_in_range_records) #Dump them with the current time so that
                last_delta=0
                stored_records=[]
                stored_in_range_records=[]
                event_start_time=float(row[1])
                detail_file.write("{0},{1:0.3f},{2},{3:0.2f},{4:0.2f}\n".format(row[1],0,0,0,0))
            else:
                stored_in_range_records.append([time,0,0,float(row[1])-event_start_time+epoch_interval])

#        stored_records.append([row[1],0,0,0])
        else:
            detail_file.write("{0},{1:0.3f},{2},{3:0.2f},{4:0.2f}\n".format(row[1],0,0,0,0))

dump_stored_data(stored_records,last_delta)
dump_stored_in_range_data(stored_in_range_records) #Dump them with the current time so that

#outage_file.write("{0},{1:0.3f},{2}\n".format(time,0.0,0)) # Write the end time so we can scale the graph correctly


summary_file.write("Total Epochs :         {0}\n".format(total_epochs))
summary_file.write("In Range:              {0:<7} {1:0.1f}%\n".format(in_range,(in_range/total_epochs)*100))
summary_file.write("Above:                 {0:<7} {1:0.1f}%\n".format(above_epochs,(above_epochs/total_epochs)*100))
summary_file.write("Below:                 {0:<7} {1:0.1f}%\n".format(below_epochs,(below_epochs/total_epochs)*100))
summary_file.write("Total Out of range:    {0:<7} {1:0.1f}%\n".format(above_epochs+below_epochs,((above_epochs+below_epochs)/total_epochs)*100))
summary_file.write("\n")
summary_file.write("Above with hysteresis: {0:<7} {1:0.1f}%\n".format(above_with_range_epochs,(above_with_range_epochs/total_epochs)*100))
summary_file.write("Below with hysteresis: {0:<7} {1:0.1f}%\n".format(below_with_range_epochs,(below_with_range_epochs/total_epochs)*100))
summary_file.write("Total with hysteresis: {0:<7} {1:0.1f}%\n".format((above_with_range_epochs+below_with_range_epochs),((above_with_range_epochs+below_with_range_epochs)/total_epochs)*100))
summary_file.write("Max outage length (s): {0:0.2f}\n".format(max_outage))

