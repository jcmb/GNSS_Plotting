#!/usr/bin/env python3

import sys
import os
import datetime
import calendar

if len(sys.argv) > 1:
    GPS_Zero = datetime.datetime(1980, 1, 6, 0, 0)
    GPS_Zero = calendar.timegm(GPS_Zero.timetuple()) * 1000
    GPS_Week = sys.argv[1]
    GPS_Week_MSecs = int(GPS_Week) * 7 * 24 * 60 * 60 * 1000
    GPS_Week_MSecs += GPS_Zero
else:
    GPS_Week_MSecs = 0

print("GPS Offset: " + str(GPS_Week_MSecs))

MAX_BANDS = 6
FIELDS_PER_BAND = 13
HEADER_FIELDS = 11
BAND_RANGE = 3
BAND_CNO = 5
BAND_SLIP = 6
BAND_ANTENNA = 9
MIN_RANGE_METERS = 1.0e7
MAX_RANGE_METERS = 5.0e7

from GNSS_Decls import System_Names, Freq_Names, Tracking_Names, Expected_SNR

Files = {}
SV_Files = {}
File_Names = {}
SV_File_Names = {}
SV_Last_Epoch = {}
antennas_seen = set()
multi_antenna_mode = False
MAX_SVs = 255


def parse_antenna(value):
    if value == "":
        return 0
    return int(value, base=10)


def valid_range(value):
    if not value:
        return False
    try:
        meters = float(value)
    except ValueError:
        return False
    return MIN_RANGE_METERS <= meters <= MAX_RANGE_METERS


def band_valid(fields, band_start):
    if band_start + BAND_ANTENNA >= len(fields):
        return False
    if fields[band_start] == "" or fields[band_start + 1] == "":
        return False
    if not valid_range(fields[band_start + BAND_RANGE]):
        return False
    try:
        freq = int(fields[band_start], base=10)
        tracking = int(fields[band_start + 1], base=10)
    except ValueError:
        return False
    if freq >= len(Freq_Names) or tracking >= len(Tracking_Names):
        return False
    return True


def iter_band_starts(fields):
    band_start = HEADER_FIELDS
    bands_found = 0
    band_limit = HEADER_FIELDS + MAX_BANDS * FIELDS_PER_BAND

    while bands_found < MAX_BANDS and band_start < band_limit:
        if band_start + FIELDS_PER_BAND > len(fields):
            break
        if band_valid(fields, band_start):
            yield band_start
            band_start += FIELDS_PER_BAND
            bands_found += 1
        else:
            band_start += 1


def file_prefix(antenna):
    if not multi_antenna_mode and antenna == 0:
        return ""
    return "Ant{}-".format(antenna)


def enable_multi_antenna_mode():
    global multi_antenna_mode
    if multi_antenna_mode:
        return
    multi_antenna_mode = True

    for key, handle in list(Files.items()):
        system, freq, tracking, antenna = key
        if antenna != 0:
            continue
        old_name = File_Names.get(key)
        if not old_name or old_name.startswith("Ant0-"):
            continue
        new_name = "Ant0-" + old_name
        handle.close()
        if os.path.exists(old_name):
            os.rename(old_name, new_name)
        Files[key] = open(new_name, 'a')
        File_Names[key] = new_name

    for key, handle in list(SV_Files.items()):
        system, sv_int, antenna = key
        if antenna != 0:
            continue
        old_name = SV_File_Names.get(key)
        if not old_name or old_name.startswith("Ant0-"):
            continue
        new_name = "Ant0-" + old_name
        handle.close()
        if os.path.exists(old_name):
            os.rename(old_name, new_name)
        SV_Files[key] = open(new_name, 'a')
        SV_File_Names[key] = new_name


def note_antenna(antenna):
    antennas_seen.add(antenna)
    if len(antennas_seen) > 1:
        enable_multi_antenna_mode()


def open_band_file(system, freq, tracking, antenna):
    key = (system, freq, tracking, antenna)
    if key in Files:
        return Files[key]

    prefix = file_prefix(antenna)
    filename = (
        prefix + System_Names[system] + "-"
        + Freq_Names[freq] + "-"
        + Tracking_Names[tracking] + ".SNR"
    )
    print("Creating:", filename)
    try:
        Files[key] = open(filename, 'a')
        File_Names[key] = filename
    except OSError:
        print(
            "Error: "
            + System_Names[system] + ","
            + Freq_Names[freq] + ","
            + Tracking_Names[tracking] + ","
            + str(antenna)
        )
        sys.exit(1)
    return Files[key]


def open_sv_file(system, sv_int, sv_label, antenna):
    key = (system, sv_int, antenna)
    if key in SV_Files:
        return SV_Files[key]

    prefix = file_prefix(antenna)
    filename = prefix + System_Names[system] + "-" + sv_label + ".SNR-SV"
    print("Creating:", filename)
    try:
        SV_Files[key] = open(filename, 'a')
        SV_File_Names[key] = filename
    except OSError:
        print("Error: " + System_Names[system] + "," + sv_label + "," + str(antenna))
        sys.exit(1)
    return SV_Files[key]


def null_sv_row(system, antenna):
    if system == 0:
        return ",,,,,,,,,,\n"
    if system == 1:
        return ",,,,,,\n"
    if system == 2:
        return ",,,,,,,,\n"
    if system in (3, 10):
        return ",,,,,,\n"
    return ",,,,,,\n"


def write_sv_row(system, sv_int, sv_label, antenna, epoch, fields, sv_snr, sv_slip):
    elev = int(fields[10])
    handle = open_sv_file(system, sv_int, sv_label, antenna)
    prefix = (
        str(epoch) + "," + fields[10] + "," + fields[9] + ','
    )

    if system == 0:
        handle.write(
            prefix
            + sv_snr.get(0, "") + ',' + sv_slip.get(0, "") + ','
            + sv_snr.get(52, "") + ',' + sv_slip.get(52, "") + ','
            + sv_snr.get(55, "") + ',' + sv_slip.get(55, "") + ','
            + sv_snr.get(108, "") + ',' + sv_slip.get(108, "") + ","
            + str(Expected_SNR[0][0][0][elev]) + "," + str(Expected_SNR[0][1][2][elev]) + ","
            + str(Expected_SNR[0][1][5][elev]) + "," + str(Expected_SNR[0][2][8][elev]) + "\n"
        )
    elif system == 1:
        handle.write(
            prefix
            + sv_snr.get(0, "") + ',' + sv_slip.get(0, "") + ','
            + sv_snr.get(106, "") + ',' + sv_slip.get(106, "") + "\n"
        )
    elif system == 2:
        handle.write(
            prefix
            + sv_snr.get(0, "") + ',' + sv_slip.get(0, "") + ','
            + sv_snr.get(1, "") + ',' + sv_slip.get(1, "") + ','
            + sv_snr.get(50, "") + ',' + sv_slip.get(50, "") + ','
            + sv_snr.get(51, "") + ',' + sv_slip.get(51, "") + ","
            + str(Expected_SNR[2][0][0][elev]) + "," + str(Expected_SNR[2][0][1][elev]) + ","
            + str(Expected_SNR[2][1][0][elev]) + "," + str(Expected_SNR[2][1][1][elev]) + "\n"
        )
    elif system == 3:
        handle.write(
            prefix
            + sv_snr.get(23, "") + ',' + sv_slip.get(23, "") + ','
            + sv_snr.get(214, "") + ',' + sv_slip.get(214, "") + "\n"
        )
    elif system == 4:
        handle.write(
            prefix
            + sv_snr.get(0, "") + ',' + sv_slip.get(0, "") + ','
            + sv_snr.get(20, "") + ',' + sv_slip.get(20, "") + ','
            + sv_snr.get(55, "") + ',' + sv_slip.get(55, "") + ','
            + sv_snr.get(108, "") + ',' + sv_slip.get(108, "") + "\n"
        )
    elif system == 10:
        handle.write(
            prefix
            + sv_snr.get(178, "") + ',' + sv_slip.get(178, "") + ','
            + sv_snr.get(326, "") + ',' + sv_slip.get(326, "") + "\n"
        )


Last_Epoch = -1
Current_Epoch = -1

for line in sys.stdin:
    line = line.rstrip()
    if not line or line.startswith("Time"):
        continue
    line = line.replace(" ", "")
    fields = line.split(",")
    if len(fields) < 71:
        continue
    try:
        Current_Epoch = GPS_Week_MSecs + int(float(fields[0]) * 1000)
    except (ValueError, IndexError):
        continue

    try:
        System = int(fields[7], base=10)
    except (ValueError, IndexError):
        continue
    if Current_Epoch != Last_Epoch:
        if Last_Epoch != -1:
            for (sv_sys, sv_num, antenna), sv_epoch in list(SV_Last_Epoch.items()):
                if sv_epoch and sv_epoch != Last_Epoch:
                    handle = SV_Files.get((sv_sys, sv_num, antenna))
                    if handle is not None:
                        handle.write(str(Last_Epoch) + null_sv_row(sv_sys, antenna))
                    SV_Last_Epoch[(sv_sys, sv_num, antenna)] = None
        Last_Epoch = Current_Epoch

    SV_int = int(fields[5], base=10)
    if System == 1:
        SV_int = SV_int - 119
    SV = fields[5]

    SV_SNR = {}
    SV_Slip = {}

    for band_start in iter_band_starts(fields):
        freq_base = band_start
        Freq = int(fields[freq_base], base=10)
        Tracking = int(fields[freq_base + 1], base=10)
        snr_field = freq_base + BAND_CNO
        slip_field = freq_base + BAND_SLIP
        antenna_field = freq_base + BAND_ANTENNA

        antenna = parse_antenna(fields[antenna_field] if antenna_field < len(fields) else "")
        note_antenna(antenna)

        tracking_index = Freq * 50 + Tracking
        if antenna not in SV_SNR:
            SV_SNR[antenna] = {}
            SV_Slip[antenna] = {}
        SV_SNR[antenna][tracking_index] = fields[snr_field]
        SV_Slip[antenna][tracking_index] = fields[slip_field]

        band_file = open_band_file(System, Freq, Tracking, antenna)
        Elev = int(fields[10])
        row = (
            str(Current_Epoch) + "," + SV + "," + fields[10] + "," + fields[9] + ","
            + fields[snr_field] + "," + fields[slip_field]
        )
        expected = Expected_SNR[System][Freq][Tracking]
        if expected:
            row += "," + str(expected[Elev])
        row += "\n"
        band_file.write(row)

    for antenna, sv_snr in SV_SNR.items():
        SV_Last_Epoch[(System, SV_int, antenna)] = Current_Epoch
        write_sv_row(System, SV_int, SV, antenna, Current_Epoch, fields, sv_snr, SV_Slip[antenna])

if antennas_seen:
    with open("Tracked.Rx", "w") as antenna_file:
        for antenna in sorted(antennas_seen):
            antenna_file.write(str(antenna) + "\n")
else:
    with open("Tracked.Rx", "w") as antenna_file:
        antenna_file.write("0\n")
