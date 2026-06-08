#!/usr/bin/env python

#import fileinput
import pprint
import sys
import datetime
import calendar

if (len(sys.argv)>1):

    GPS_Zero = datetime.datetime(1980, 1,6, 0, 0)
    GPS_Zero=calendar.timegm(GPS_Zero.timetuple())*1000

    GPS_Week=sys.argv[1]
    GPS_Week_MSecs=int(GPS_Week)*7*24*60*60*1000
    GPS_Week_MSecs+=GPS_Zero
else:
    GPS_Week_MSecs=0

print "GPS Offset: " + str(GPS_Week_MSecs)

MAX_BANDS=6
FIELDS_PER_BAND=12
#FIELDS_PER_BAND=10

#MAX_BANDS=6
#FIELDS_PER_BAND=12
#last_file=""

from GNSS_Decls import System_Names, Freq_Names, Tracking_Names, Expected_SNR


#print Tracking_Names[11]
#quit()

#Files[0:len(System_Names)]=0

Files = [[[None] * len (Tracking_Names)] * len (Freq_Names)] * len(System_Names)
Files = [None] * len(System_Names)
SV_Files = [None] * len(System_Names)
SV_Last_Epoch = [None] * len(System_Names)

MAX_SVs=255
for s in range(len(System_Names)): #Make the 2D arrays to store the SV Dependent information. So wish there are real records in python.
    Files[s]=[None] * len (Freq_Names)
    SV_Files[s] = [None] * MAX_SVs # Yes this is to many but we don't care. The SBAS PRN's are 120-158 are moved down to 1..39 in the range
    SV_Last_Epoch[s] = [None] * MAX_SVs

for s in range(len(System_Names)):
   for f in range(len(Freq_Names)):
      Files[s][f]=[None] * len (Tracking_Names) # Yes also to many

#print Files
#pprint.PrettyPrinter(Files)

#print 0
#print Files[0]
#print Files[0][0]

#Making the files by going over all the combos and then excluding the ones that don't exist seemed like a good idea
#when it was got GPS/GLO only. So after lots of trying ot work out real combinations we just don't care and only make the files when we see the data
#the first time, which is a much nicer solution as well

"""

            filename = System + "." + Freq + "." + Tracking + ".SNR"

#            print filename
#            print str(System_Names.index(System)) + " "  + str(Freq_Names.index(Freq)) + " "  + str(Tracking_Names.index(Tracking))
#            print str(System_Names.index(System)) +"," + str(Freq_Names.index(Freq)) +","+ str(Tracking_Names.index(Tracking)) + "," + filename
            Files[System_Names.index(System)][Freq_Names.index(Freq)][Tracking_Names.index(Tracking)] = open(filename, 'a')
#            Files[System_Names.index(System)][Freq_Names.index(Freq)][Tracking_Names.index(Tracking)].write(filename+"\n")

"""

Last_Epoch=-1
Current_Epoch=-1

#for line in fileinput.input():
for line in sys.stdin:
#   if fileinput.isfirstline() :
#       if fileinput.isstdin() :
#           print "Processing: Standard Input"
#       else :
#           print "Processing:",fileinput.filename()
   line=line.rstrip()
   line=line.replace(" ","")
   fields=line.split(",")
   if len(fields) < 71 :
      continue
   try :
       Current_Epoch=GPS_Week_MSecs+int(float(fields[0])*1000)
   except :
      continue

   SV_SNR  = {}
   SV_Slip = {}

   System = int(fields[7],base=10)
#   Current_Epoch=float(fields[0])
#   print Last_Epoch,Current_Epoch
   if Current_Epoch != Last_Epoch :
      if Last_Epoch != -1: #We have changed epochs
         # So we need to write a null record for SV's that did not get anything from the SV
#         print Last_Epoch,Current_Epoch
#         print "Before System"
         for SV_Sys in range(len(System_Names)):
            for SV_Num in range (MAX_SVs):
               SV_Epoch= SV_Last_Epoch[SV_Sys][SV_Num]
               if SV_Epoch and (SV_Epoch != Last_Epoch):
                  if SV_Epoch >= 0:
#                     print "About to write a null"
#                     print SV_Sys,SV_Num, SV_Epoch
#                     print SV_Epoch, Last_Epoch
                     if SV_Sys == 0 : # GPS L1 C/A, L2 E, L2 CS, L5 I&Q
                     #         print System, SV_Tracking
                       SV_Files[SV_Sys][SV_Num].write(str(Last_Epoch) + ",,,,,,,,,,\n")
                     elif SV_Sys == 1 : # GPS L1 C/A, L5 I
                       SV_Files[SV_Sys][SV_Num].write(str(Last_Epoch)+",,,,,,\n")
                     elif SV_Sys == 2 : # GLONASS, L1 C/A, L1 P, L2 P
                       SV_Files[SV_Sys][SV_Num].write(str(Last_Epoch)+",,,,,,,,\n")
                     elif SV_Sys == 3 : # GAL, 2
                       SV_Files[SV_Sys][SV_Num].write(str(Last_Epoch)+",,,,,,\n")
                     elif SV_Sys == 10 : # GAL, L1, ,
                       SV_Files[SV_Sys][SV_Num].write(str(Last_Epoch)+",,,,,,\n")
                     #      Files[System][Freq][Tracking].write(fields[0]+","+ fields[5] + "," + fields[10] + ","+ fields[9] + "," +fields[16+ band*10]+ "," +fields[18 + band*10] +"\n")
                     SV_Last_Epoch[SV_Sys][SV_Num]=None
      Last_Epoch=Current_Epoch


   SV_int=int(fields[5],base=10)
   if System == 1:
      SV_int=SV_int-119
   SV=fields[5]
#   print System,SV_int,Current_Epoch
   SV_Last_Epoch[System][SV_int]=Current_Epoch
   Viewdat_Error_Hack=0


# The current 6.192 version of viewdat has an error in which it only outputs 10 blank fields for a band without observations, instead of the standard 12. 
# This was added when the number of fields per bands went from 10 to 12.                                                                                                                                                        
# So if the range is 0 (blank), we add 2 to the hack so the next band is in the right place.

#   pprint.pprint(fields)

   for band in range (MAX_BANDS):
#      print "band", band , " Hack ", Viewdat_Error_Hack, " Range ", fields[14+ band*FIELDS_PER_BAND - Viewdat_Error_Hack]
      if fields[14+ band*FIELDS_PER_BAND - Viewdat_Error_Hack] == "" :
          Viewdat_Error_Hack+=2
#          print "Time",Current_Epoch,"SV",SV,"band", band , " Hack ", Viewdat_Error_Hack, " Range ", fields[14+ band*FIELDS_PER_BAND - Viewdat_Error_Hack]
#          print "Viewdat Error Hack: ",Viewdat_Error_Hack
      else : #  fields[12+band *FIELDS_PER_BAND - Viewdat_Error_Hack] :
#         print "*",fields[11+ band*12],"*"
#         pprint.pprint(int(fields[11+ band*FIELDS_PER_BAND],base=10))
         Freq = int(fields[11+ band*FIELDS_PER_BAND - Viewdat_Error_Hack],base=10)
         Tracking= int(fields[12+ band*FIELDS_PER_BAND - Viewdat_Error_Hack], base=10)
         SV_SNR[Freq*50 + Tracking] = fields[16+ band*FIELDS_PER_BAND - Viewdat_Error_Hack]
         SV_Slip[Freq*50 + Tracking] = fields[18+ band*FIELDS_PER_BAND - Viewdat_Error_Hack]

#         if System==10:
#            print System,SV_int,band,Freq,Tracking,Viewdat_Error_Hack,Freq*50 + Tracking
#         print fields[14+ band*FIELDS_PER_BAND - Viewdat_Error_Hack]



         if  (Files[System][Freq][Tracking] is None) :
             filename = System_Names[System] + "-" + Freq_Names[Freq] + "-" + Tracking_Names[Tracking] + ".SNR"
#             print fileinput.filename(), "Creating:" , filename
             print "Creating:" , filename
             try :
                Files[System][Freq][Tracking] = open(filename, 'a')
         #                    print "Created: " + filename
             except :
                print fileinput.filename()
                print "Error: " + str(Current_Epoch) + "," + SV + "," + str(System) + "," + str(Freq) + "," + str(Tracking)
                print "Error: " + System_Names[System] + "," + Freq_Names[Freq] + "," + Tracking_Names[Tracking]
                quit()

         Elev=int(fields[10])
         if Expected_SNR[System][Freq][Tracking]:
             Files[System][Freq][Tracking].write(str(Current_Epoch)+","+ SV + "," + fields[10] + ","+ fields[9] + "," +fields[16+ band*FIELDS_PER_BAND]+ "," +fields[18 + band*FIELDS_PER_BAND] + "," + str(Expected_SNR[System][Freq][Tracking][Elev])+"\n")
         else:
             Files[System][Freq][Tracking].write(str(Current_Epoch)+","+ SV + "," + fields[10] + ","+ fields[9] + "," +fields[16+ band*FIELDS_PER_BAND]+ "," +fields[18 + band*FIELDS_PER_BAND] +"\n")

#   print System, SV_Tracking
#   print "In Try"
#   print SV_Files == {}
#   print "after Try"

   try :
      if  (SV_Files[System][SV_int] is None) :
         filename = System_Names[System] + "-" + SV +".SNR-SV"
#         print fileinput.filename(), "Creating:" , filename
         print "Creating:" , filename
         SV_Files[System][SV_int] = open(filename, 'a')
#         print "Created: " + filename
   except:
#      print fileinput.filename()
      print "Error: " + str(Current_Epoch) + "," + str(System) + "," + str(SV) + ","
      print "Error: " + System_Names[System] + "," + SV
      quit()

#   print System, SV_int, Elev
   if System == 0 : # GPS L1 C/A, L2 E, L2 CS, L5 I&Q
      SV_Files[System][SV_int].write(str(Current_Epoch)+ "," + fields[10] + "," + fields[9] + ',' + SV_SNR.get(0,"") +  ',' + SV_Slip.get(0,"") + ',' + SV_SNR.get(52,"") + ',' + SV_Slip.get(52,"") + ','+ SV_SNR.get(55,"") + ','+ SV_Slip.get(55,"")+ ',' + SV_SNR.get(108,"") + ',' + SV_Slip.get(108,"") + "," + str(Expected_SNR[0][0][0][Elev]) + "," + str(Expected_SNR[0][1][2][Elev]) + "," + str(Expected_SNR[0][1][5][Elev]) + "," + str(Expected_SNR[0][2][8][Elev]) +"\n")
   elif System == 1 : # SBAS GPS L1 C/A, L5 I
      SV_Files[System][SV_int].write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(0,"") +  ',' + SV_Slip.get(0,"") + ',' + SV_SNR.get(106,"") + ',' + SV_Slip.get(106,"") + "\n")
   elif System == 2 : # GLONASS, L1 C/A, L1 P, L2 C/A, L2 P
#      if SV_int == 21 :
#          sys.stderr.write("GLONASS 19\n")
#          sys.stderr.write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(0,"") + ',' + SV_Slip.get(0,"") +  ',' + SV_SNR.get(1,"") +  ',' + SV_Slip.get(1,"")  + ',' + SV_SNR.get(50,"")  + ',' + SV_Slip.get(50,"")  + ',' + SV_SNR.get(51,"")  + ',' + SV_Slip.get(51,"") +  "," + str(Expected_SNR[2][0][0][Elev]) + "," + str(Expected_SNR[2][0][1][Elev]) + "," + str(Expected_SNR[2][2][0][Elev]) + "," + str(Expected_SNR[2][2][1][Elev]) +"\n")
      SV_Files[System][SV_int].write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(0,"") + ',' + SV_Slip.get(0,"") +  ',' + SV_SNR.get(1,"") +  ',' + SV_Slip.get(1,"")  + ',' + SV_SNR.get(50,"")  + ',' + SV_Slip.get(50,"")  + ',' + SV_SNR.get(51,"")  + ',' + SV_Slip.get(51,"") +  "," + str(Expected_SNR[2][0][0][Elev]) + "," + str(Expected_SNR[2][0][1][Elev]) + "," + str(Expected_SNR[2][2][0][Elev]) + "," + str(Expected_SNR[2][2][1][Elev]) +"\n")
   elif System == 3 : # GALILEO, L1 MBOC_1_1_PD, E5AB ALTBOC_C_PD,
      SV_Files[System][SV_int].write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(23,"") +  ',' + SV_Slip.get(23,"") + ',' + SV_SNR.get(214,"") + ',' + SV_Slip.get(214,"")+"\n")
   elif System == 4 : # QZSS, L1 CA, L1-BOC_1_1_PD, L1-SAIF, L2-CS, L5-IQ
      SV_Files[System][SV_int].write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(0,"") +  ',' + SV_Slip.get(0,"") + ',' + SV_SNR.get(20,"") + ',' + SV_Slip.get(20,"")+','+ SV_SNR.get(55,"") + ','+ SV_Slip.get(55,"")+ ',' + SV_SNR.get(108,"") + ',' + SV_Slip.get(108,"")+"\n")
   elif System == 10 : # BDS B1 BPSK2_B1, BPSK2_B2
      SV_Files[System][SV_int].write(str(Current_Epoch)+"," + fields[10] + ","+ fields[9] + ',' + SV_SNR.get(178,"") +  ',' + SV_Slip.get(178,"") + ',' + SV_SNR.get(326,"") + ',' + SV_Slip.get(326,"")+"\n")
#      for field in range(len(fields)):
#          if fields[field]:
#              print str(field) + ': ' + fields[field]

#      Files[System][Freq][Tracking].write(fields[0]+","+ fields[5] + "," + fields[10] + ","+ fields[9] + "," +fields[16+ band*10]+ "," +fields[18 + band*10] +"\n")
   else:
       pass
#      print "Unknown",System, Tracking

#            Files[System][Freq][Tracking].write(fields[0]+","+str(System)+","+ str(Freq) + "," + str(Tracking)+ "," + str(fields[5]) + "," + fields[10] + ","+ fields[9] + "," +fields[16+ band*10]+"\n")

#     If we are here we have 71 fields and the first field is a number, we call it a X29 file
#     This is done because the -X format files have a header, and since we are using fileinput.input()
#     we may get mutiple files from the command line
