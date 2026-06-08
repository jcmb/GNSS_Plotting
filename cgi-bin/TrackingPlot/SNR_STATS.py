#!/usr/bin/env python3
import sys
sys.path.append("/Users/gkirk/Dropbox/git/Library/")
sys.path.append(".")
import os
import csv
from Stream_SD import Stats_Stream


# File format is Time,SV,Elev,Az,SNR

def Compute_Stats (Signal):
    Elev_Stats=list(range(91))
    for elev in range (91):
        Elev_Stats[elev]=Stats_Stream()
    if os.path.isfile(Signal):
        SignalFile=open(Signal, 'r')
        Reader=csv.reader(SignalFile)
        for row in Reader:
#            print row
#            print row[1],row[2],row[4]
            if int(row[2])<=90:
               Elev_Stats[int(row[2])].add_item(row[4])
            """
            fields=line
            Current_Elev=
            Current_SNR=
            """
        SignalFile.close()
    return Elev_Stats

def Ouput_Stats (FileName,Stats):
    StatsFile=open(FileName, 'w')
#    StatsFile.write( "Elev,N,Mean,SD,Min,Max\n")

    for elev in range (91):
#        print elev, L1_Stats[elev]
        StatsFile.write( "{0},{1},{2:0.1f},{3:0.1f},{4},{5}\n".format(elev,Stats[elev].N(),Stats[elev].Mean(),Stats[elev].SD(),Stats[elev].Min(),Stats[elev].Max()))
    StatsFile.close()


L1_Stats = Compute_Stats("GLONASS-L1-CA.SNR")
Ouput_Stats("GLONASS-L1-CA.MEAN",L1_Stats)
L1_P_Stats = Compute_Stats("GLONASS-L1-P.SNR")
Ouput_Stats("GLONASS-L1-P.MEAN",L1_P_Stats)
L2_CA_Stats = Compute_Stats("GLONASS-L2-CA.SNR")
Ouput_Stats("GLONASS-L2-CA.MEAN",L2_CA_Stats)
L2_P_Stats = Compute_Stats("GLONASS-L2-P.SNR")
Ouput_Stats("GLONASS-L2-P.MEAN",L2_P_Stats)

L1_Stats = Compute_Stats("GPS-L1-CA.SNR")
Ouput_Stats("GPS-L1-CA.MEAN",L1_Stats)
L2_E_Stats = Compute_Stats("GPS-L2-E.SNR")
Ouput_Stats("GPS-L2-E.MEAN",L2_E_Stats)
L2_CS_Stats = Compute_Stats("GPS-L2-CS.SNR")
Ouput_Stats("GPS-L2-CS.MEAN",L2_CS_Stats)
L5_IQ_Stats = Compute_Stats("GPS-L5-IQ.SNR")
Ouput_Stats("GPS-L5-IQ.MEAN",L5_IQ_Stats)


L1_Stats = Compute_Stats("SBAS-L1-CA.SNR")
Ouput_Stats("SBAS-L1-CA.MEAN",L1_Stats)
L5_I_Stats = Compute_Stats("SBAS-L5-I.SNR")
Ouput_Stats("SBAS-L5-I.MEAN",L5_I_Stats)
