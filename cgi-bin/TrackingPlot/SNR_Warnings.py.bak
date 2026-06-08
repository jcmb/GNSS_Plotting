#!/usr/bin/env python

import sys
import argparse
import csv
import os


Verbose=0

TIME_Field=0
SV_Field=1
Elev_Field=2
Az_Field=3
SNR_Field=4
Slip_Field=5
Expected_SNR_Field=6

def process_arguments():
   argp = argparse.ArgumentParser()
   argp.epilog="JCMBSoft"
   argp.add_argument('--version', action='version', version='%(prog)s v0.1')
   argp.add_argument('-I', '--Input', type=argparse.FileType('r'), required=True,help="SNR File")
   argp.add_argument('-T', '--Tolerance', type=float, default=5,help="Amount SNR can be below expected SNR and still be OK. Default 5")
   argp.add_argument('-O', '--Output', type=argparse.FileType('w'), required=True,help="Outage File")
   argp.add_argument('--Number', type=int, default=2, help="Number of SV's that must be outside tolerance in an epoch for it to count as bad. Default 2")
   argp.add_argument('-n', '--Name', type=str, help="Name for the file in plots")
   argp.add_argument('-e', '--Elev', type=float, default=15,help="Ignore SV's below this elevation. Default=15")
   argp.add_argument('-v', '--verbose', action='count', default=0,
                      help='increase output verbosity (use up to 3 times)')
   args = argp.parse_args()

   return args


def Process_Single_Band(Base_Name,Band_Name,SNR_File,Tolerance, Number_Outside_Tolerance,Tolerance_Output_File,Elevation_Mask):

   Epochs_Outside_Tolerance=0

   if Verbose:
       sys.stderr.write("Process Single Band:\n")
       sys.stderr.write("Base Name: " + str(Base_Name)+"\n")
       sys.stderr.write("Band Name: " + str(Band_Name)+"\n")
       sys.stderr.write("Input File: " + str(SNR_File.name)+"\n")
       sys.stderr.write("Output File: " + str(Tolerance_Output_File.name)+"\n")
       sys.stderr.write("Elevation_Mask: " + str(Elevation_Mask)+"\n")


   SNR_CSV=csv.reader(SNR_File)
   Tolerance_CSV=csv.writer(Tolerance_Output_File)

   Current_Time=-1
   Epoch=None
   Outside_Tolerance=0
   Total_Epochs=0
   SV_Measurements=0
   SV_Outside_Tolerance=0

   for SNR_Row in SNR_CSV:
      SNR_Row_Time=int(SNR_Row[TIME_Field])
      SV_Measurements+=1
      if Current_Time <> SNR_Row_Time:
         Total_Epochs+=1
         if Epoch != None:
#            print Epoch
            Tolerance_CSV.writerow([Current_Time,Outside_Tolerance, len(Epoch)])
            if Outside_Tolerance>=Number_Outside_Tolerance:
                  Epochs_Outside_Tolerance+=1

         Current_Time=SNR_Row_Time
         Outside_Tolerance=0
         Epoch={}
      if float(SNR_Row[Elev_Field]) >= Elevation_Mask:
         Epoch[int(SNR_Row[SV_Field])]=SNR_Row
         SNR=float(SNR_Row[SNR_Field])
         Expected_SNR=float(SNR_Row[Expected_SNR_Field])
         if Expected_SNR-SNR>Tolerance:
            Outside_Tolerance+=1
            SV_Outside_Tolerance+=1

   if Epoch:
#      print L1_Epoch
        Tolerance_CSV.writerow([Current_Time,Outside_Tolerance, len(Epoch)])
        if Outside_Tolerance>=Number_Outside_Tolerance:
               Epochs_Outside_Tolerance+=1

   return (Epochs_Outside_Tolerance,Total_Epochs,SV_Outside_Tolerance,SV_Measurements)


def main():

   global Verbose
   args=process_arguments()
   Verbose=args.verbose
   File=args.Input
   Output_File=args.Output
   Tolerance=args.Tolerance
   Number_Outside_Tolerance=args.Number

#   (Dir,File_Name)=os.path.split(File.name)

   File_Name=os.path.basename(File.name)
   File_Name=File_Name[:-4]
   Base_Name=args.Name

   if Base_Name==None:
      Base_Name=""

   if Verbose:
       sys.stderr.write("Base Name: " + Base_Name+"\n")
       sys.stderr.write("Input File: " + str(File.name)+"\n")


   (outside,total,SV_Outside_Tolerance,SV_Measurements)=Process_Single_Band(Base_Name,File_Name,File,Tolerance,Number_Outside_Tolerance,Output_File,args.Elev)
   print Base_Name+','+File.name+","+str(outside)+","+str(total)+","+str(float(outside)/float(total)*100.0)+","+str(SV_Outside_Tolerance)+","+str(SV_Measurements)+","+str(float(SV_Outside_Tolerance)/float(SV_Measurements)*100.0)


if __name__ == '__main__':
    main()
