#!/usr/bin/env python3

import re
import sys

from antenna_names import split_antenna_prefix, read_tracked_antennas, file_prefix_for_antennas


def output_plot_header(t_min, t_max):
    print("""
        set datafile separator ","
        set terminal png size 1000,800 noenhanced
        set xtics border mirror
        set grid xtics ytics lt 9
        #set mxtics 5
        set style data lines
        set xlabel "GPS Time"

        set key outside

        set xdata time
        set timefmt "%s"
        set format x "%H:%M"

        set yrange [10:60]
        set ylabel "SNR"
        set y2range [0:90]
        set y2tics
        set y2label "Elevation"

    """)
    print("set xrange[{}:{}]".format(t_min, t_max))


def output_plot(System, sv_file, plot_base, HTML_File, Plot_Name):
    HTML_File.write('<a name="{}">'.format(plot_base))
    HTML_File.write('<img src="{}.SNR.png"'.format(plot_base))
    HTML_File.write('alt="{}.SNR.png">'.format(plot_base))
    HTML_File.write("<p/><p/>\n")
    print("")
    print('set output "{}.SNR.png"'.format(plot_base))
    print('set title "{} {} SNRs"'.format(Plot_Name, sv_file))
    print("")
    print("plot \\")
    data_file = sv_file + ".SNR-SV"
    if System == "GPS":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "L2 E"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 8, "L2 CS"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 10, "L5 IQ"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 12, "Exp L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 13, "Exp L2 E"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 14, "Exp L2 CS"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 15, "Exp L5 IQ"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))

    elif System == "GLONASS":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "L1 P"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 8, "L2 CA"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 10, "L2 P"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 12, "Exp L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 13, "Exp L1 P"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 14, "Exp L2 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 15, "Exp L2 P"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))
    elif System == "GAL":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "E1"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "AltBoc"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))
    elif System == "BDS":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "B1"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "B2a"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 8, "B2b"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 10, "B2I"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 12, "B3"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))
    elif System == "SBAS":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "L5 IQ"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))
    elif System == "QZSS":
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 4, "L1 C/A"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 6, "L1 BOC_1_1_PD"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 8, "L1 SAIF"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 10, "L2 CS"))
        print("'{}' using ($1/1000):(${}) title \"{}\",\\".format(data_file, 12, "L5 IQ"))
        print("'{}' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(data_file))
    else:
        sys.exit("Internal Error, Unknown SV Type: " + System)

    print("")


def create_Sys_Plots(Sys, SV_Entries, HTML_File, Name):
    for sv_file, plot_base, _sv_num in SV_Entries:
        output_plot(Sys, sv_file, plot_base, HTML_File, Name)


def create_plots(sv_entries, HTML_File, Plot_Name):
    create_Sys_Plots("GPS", sv_entries["GPS"], HTML_File, Plot_Name)
    create_Sys_Plots("GLONASS", sv_entries["GLONASS"], HTML_File, Plot_Name)
    create_Sys_Plots("SBAS", sv_entries["SBAS"], HTML_File, Plot_Name)
    create_Sys_Plots("GAL", sv_entries["GAL"], HTML_File, Plot_Name)
    create_Sys_Plots("BDS", sv_entries["BDS"], HTML_File, Plot_Name)
    create_Sys_Plots("QZSS", sv_entries["QZSS"], HTML_File, Plot_Name)


def read_SVs(antennas):
    sv_entries = {
        "GPS": [], "GLONASS": [], "SBAS": [], "GAL": [], "BDS": [], "QZSS": []
    }

    with open("Tracked.SVs", "r") as SVs_file:
        for SV in SVs_file:
            SV = SV.strip()
            if not SV:
                continue
            antenna, rest = split_antenna_prefix(SV)
            match = re.search(r'(.*)-(.*)', rest)
            if match:
                Sys = match.group(1).upper()
                sv_num = int(match.group(2))
                plot_base = file_prefix_for_antennas(antennas, antenna) + Sys + "-" + str(sv_num)
                if Sys in sv_entries:
                    sv_entries[Sys].append((SV, plot_base, sv_num))
                else:
                    sys.exit("Internal Error, Unknown SV Type: " + Sys)
            else:
                sys.exit("Internal Error, could not decode Tracked SVs: " + SV)

    for system in sv_entries:
        sv_entries[system].sort(key=lambda item: item[2])

    return sv_entries


def create_html_header(HTML_File, Name):
    HTML_File.write("""
<html>
<head>
<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">
<title>
    """)
    HTML_File.write("Single SV Tracking PNG's for " + Name)
    HTML_File.write("""
</title>
</head>
<body class="page">
<div class="container clearfix">
  <div style="padding: 10px 10px 10px 0 ;"> <a href="/">
        <img src="/images/trimble-logo.jpg" alt="Trimble Logo" id="logo"> </a>
      </div>
  <!-- end #logo-area -->
</div>
<div id="top-header-trim"></div>
<div id="content-area">
<div id="content">
<div id="main-content">
""")
    HTML_File.write("<h1>Single SV Tracking for " + Name + "</h1><p/>")


def close_html_file(HTML_File):
    HTML_File.write("""
</body>
</html>""")


def create_html_Single_TOC(HTML_File, System, SV_Entries):
    HTML_File.write("<bold>{}: </bold>".format(System))
    for _sv_file, plot_base, sv_num in SV_Entries:
        HTML_File.write('<a href="#{}">{}</a>\n'.format(plot_base, sv_num))
    HTML_File.write("<br/>")


def create_html_TOC(HTML_File, sv_entries):
    if sv_entries["GPS"]:
        create_html_Single_TOC(HTML_File, "GPS", sv_entries["GPS"])
    if sv_entries["GLONASS"]:
        create_html_Single_TOC(HTML_File, "GLONASS", sv_entries["GLONASS"])
    if sv_entries["GAL"]:
        create_html_Single_TOC(HTML_File, "GAL", sv_entries["GAL"])
    if sv_entries["BDS"]:
        create_html_Single_TOC(HTML_File, "BDS", sv_entries["BDS"])
    if sv_entries["SBAS"]:
        create_html_Single_TOC(HTML_File, "SBAS", sv_entries["SBAS"])
    if sv_entries["QZSS"]:
        create_html_Single_TOC(HTML_File, "QZSS", sv_entries["QZSS"])


def determine_SV_time_range():
    t_min = 1000000000000000
    t_max = -2

    with open("Tracked.SVs", "r") as SVs_file:
        for SV in SVs_file:
            SV = SV.strip()
            if not SV:
                continue
            first_line = None
            last_line = None
            with open(SV + ".SNR-SV", "r") as SV_File:
                for line in SV_File:
                    if first_line is None:
                        first_line = line
                    last_line = line
            if first_line:
                m = re.search(r'(.*?),.*', first_line)
                if m and float(m.group(1)) < t_min:
                    t_min = float(m.group(1))
            if last_line:
                m = re.search(r'(.*?),.*', last_line)
                if m and float(m.group(1)) > t_max:
                    t_max = float(m.group(1))

    return (t_min, t_max)


if len(sys.argv) <= 1:
    sys.exit("Name for plots must be provided on the command line")

Plot_Name = sys.argv[1]
antennas = read_tracked_antennas()
sv_entries = read_SVs(antennas)

HTML_File = open("PNGs_SVs.html", "w")

create_html_header(HTML_File, Plot_Name)

(t_min, t_max) = determine_SV_time_range()
t_min = t_min / 1000
t_max = t_max / 1000

output_plot_header(t_min, t_max)

create_html_TOC(HTML_File, sv_entries)

create_plots(sv_entries, HTML_File, Plot_Name)

close_html_file(HTML_File)
