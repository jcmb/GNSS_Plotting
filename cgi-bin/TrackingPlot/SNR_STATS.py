#!/usr/bin/env python3

import glob
import os
import csv
from Stream_SD import Stats_Stream


# File format is Time,SV,Elev,Az,SNR

def Compute_Stats(Signal):
    Elev_Stats = [Stats_Stream() for _ in range(91)]
    if os.path.isfile(Signal):
        with open(Signal, 'r') as SignalFile:
            Reader = csv.reader(SignalFile)
            for row in Reader:
                if int(row[2]) <= 90:
                    Elev_Stats[int(row[2])].add_item(row[4])
    return Elev_Stats


def Ouput_Stats(FileName, Stats):
    with open(FileName, 'w') as StatsFile:
        for elev in range(91):
            StatsFile.write("{0},{1},{2:0.1f},{3:0.1f},{4},{5}\n".format(
                elev, Stats[elev].N(), Stats[elev].Mean(), Stats[elev].SD(),
                Stats[elev].Min(), Stats[elev].Max()))


for signal in sorted(glob.glob('*.SNR')):
    Ouput_Stats(signal[:-4] + ".MEAN", Compute_Stats(signal))
