#!/usr/bin/env python3

import re
import sys

from antenna_names import split_antenna_prefix, read_tracked_antennas, file_prefix_for_antennas


def output_plot_header (t_min,t_max):
    print("""
        set datafile separator ","
        set terminal png size 1000,800 noenhanced font '/usr/share/fonts/msttcorefonts/arial.ttf' 10
        set xtics border mirror
        set grid xtics ytics lt 9
        #set mxtics 5
        set style data lines
        set xlabel "GPS Time"

        set xdata time
        set timefmt "%s"
        set format x "%H:%M"

        set key outside

        set yrange [10:60]
        set ylabel "SNR"
    """)

    print("set xrange[{}:{}]".format(t_min,t_max))


def output_plot (Antenna_Prefix,System,Band_Name,Tracking,Field,SVs,HTML_File,Plot_Name):
    plot_base = Antenna_Prefix + System + "-" + Band_Name + "-" + Tracking
    HTML_File.write('<h3>{} {}{}</h3>'.format(System,Band_Name,Tracking))
    HTML_File.write('<a name="{}"/>'.format(plot_base))
    HTML_File.write('<img src="{}.SNRs.png"'.format(plot_base))
    HTML_File.write('alt="{}.SNRs.png">'.format(plot_base))
    HTML_File.write("<p/><p/>\n")
    print("")
    print('set output "{}.SNRs.png"'.format(plot_base))
    print('set title "{} {} {} {} SNRs"'.format(Plot_Name,System,Band_Name,Tracking))
    print("")
    print("plot \\")
    first = True
    for SV in SVs:
       if first:
            first=False
       else:
          print(",\\")
       print("'{}.SNR-SV' using ($1/1000):(${}) title \"{}\"".format(SV,Field,SV.split("-")[-1]), end="")

    print("")

def read_Bands_and_create_plots(antennas, sv_by_antenna, HTML_File, Plot_Name):
    def svs(system, antenna):
        return sv_by_antenna.get(antenna, {}).get(system, [])

    def prefix(antenna):
        return file_prefix_for_antennas(antennas, antenna)

    Bands_file=open("Tracked.Bands","r")
    for Band in Bands_file:
        Band=Band.strip()
        antenna, rest = split_antenna_prefix(Band)
        m=re.search('(.*)-(.*)-(.*)',rest)
#        print m.group(1),m.group(2),m.group(3)

        if m:
            Sys=m.group(1).upper()
            Band=m.group(2).upper()
            Tracked=m.group(3).upper()
            if Sys=="GPS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("GPS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="E":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("GPS", antenna),HTML_File,Plot_Name)
                    elif Tracked=="CS":
                        output_plot(prefix(antenna),Sys,Band,Tracked,8,svs("GPS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L2 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="IQ":
                        output_plot(prefix(antenna),Sys,Band,Tracked,10,svs("GPS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GPS Band: " + Band)


            elif Sys=="GLONASS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("GLONASS", antenna),HTML_File,Plot_Name)
                    elif Tracked=="P":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("GLONASS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GLONASS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="CA":
                        output_plot(prefix(antenna),Sys,Band,Tracked,8,svs("GLONASS", antenna),HTML_File,Plot_Name)
                    elif Tracked=="P":
                        output_plot(prefix(antenna),Sys,Band,Tracked,10,svs("GLONASS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GLONASS L2 Tracked: " + Tracked)

                elif Band=="G3":
                    if Tracked=="G3_PD":
#                        output_plot(prefix(antenna),Sys,Band,Tracked,12,svs("GLONASS", antenna),HTML_File,Plot_Name)
                        pass
                    else:
                        sys.exit("Internal Error, Unknown GLONASS G3 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GLONASS Band: " + Band)


            elif Sys=="SBAS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("SBAS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown SBAS L1 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="I":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("SBAS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown SBAS L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown SBAS Band: " + Band)

            elif Sys=="GAL":
                if Band=="L1":
                    if Tracked=="MBOC_1_1_PD":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("GAL", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL L1 Tracked: " + Tracked)
                elif Band=="E5AB":
                    if Tracked=="ALTBOC_C_PD":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("GAL", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL E5AB Tracked: " + Tracked)
                elif Band=="E5B":
                    if Tracked=="BPSK_PD":
                        output_plot(prefix(antenna),Sys,Band,Tracked,8,svs("GAL", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL E5B Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="BPSK_PD":
                        output_plot(prefix(antenna),Sys,Band,Tracked,10,svs("GAL", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GAL Band: " + Band)

            elif Sys=="BDS":
                if Band=="B1_E2":
                    if Tracked=="BPSK2_B1":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("BDS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS L1 Tracked: " + Tracked)
                elif Band=="E5B":
                    if Tracked=="BPSK2_B2":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("BDS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS L5 Tracked: " + Tracked)
                elif Band=="B3":
                    if Tracked=="BPSK2_B3":
                        output_plot(prefix(antenna),Sys,Band,Tracked,8,svs("BDS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS B3 Tracked: " + Tracked)
            elif Sys=="QZSS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(prefix(antenna),Sys,Band,Tracked,4,svs("QZSS", antenna),HTML_File,Plot_Name)
                    elif Tracked=="BOC_1_1_PD":
                        output_plot(prefix(antenna),Sys,Band,Tracked,6,svs("QZSS", antenna),HTML_File,Plot_Name)
                    elif Tracked=="SAIF":
                        output_plot(prefix(antenna),Sys,Band,Tracked,8,svs("QZSS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown QZSS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="CS":
                        output_plot(prefix(antenna),Sys,Band,Tracked,10,svs("QZSS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown QZSS L2 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="IQ":
                        output_plot(prefix(antenna),Sys,Band,Tracked,12,svs("QZSS", antenna),HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown QZSS L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown QZSS Band: " + Band)
            else:
                sys.exit("Internal Error, Unknown SV Type: " + Sys)

        else:
            sys.exit("Internal Error, could not decode Tracked Bands: " + Band)


    Bands_file.close()

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


def read_SVs_by_antenna():
    sv_by_antenna = {}

    def ensure_antenna(antenna):
        if antenna not in sv_by_antenna:
            sv_by_antenna[antenna] = {
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
                if Sys in ("GPS", "GLONASS", "SBAS", "GAL", "BDS", "QZSS"):
                    ensure_antenna(antenna)
                    sv_by_antenna[antenna][Sys].append(SV)
                else:
                    sys.exit("Internal Error, Unknown SV Type: " + Sys)
            else:
                sys.exit("Internal Error, could not decode Tracked SVs: " + SV)

    for antenna in sv_by_antenna:
        for system in sv_by_antenna[antenna]:
            sv_by_antenna[antenna][system].sort(key=lambda item: int(item.split("-")[-1]))

    return sv_by_antenna


def read_Bands_and_create_header(antennas, HTML_File):
    HTML_File.write('<h2>Bands Tracked</h2>')
    Bands_file=open("Tracked.Bands","r")
    for Band in Bands_file:
        Band=Band.strip()
        if not Band:
            continue
        antenna, rest = split_antenna_prefix(Band)
        match = re.search('(.*)-(.*)-(.*)', rest)
        if match:
            System=match.group(1).upper()
            Band_Name=match.group(2).upper()
            Tracked=match.group(3).upper()
            plot_base = file_prefix_for_antennas(antennas, antenna) + System + "-" + Band_Name + "-" + Tracked
            label = Band if len(antennas) > 1 else "{} {} {}".format(System, Band_Name, Tracked)
            HTML_File.write('<a href="#{}">'.format(plot_base))
            HTML_File.write(label)
            HTML_File.write('</a><br>')
    HTML_File.write('<p/>')
    if len(antennas) > 1:
        HTML_File.write('<h2>Plots by Antenna</h2>')
    else:
        HTML_File.write('<h2>Plots</h2>')
    Bands_file.close()

def create_html_header(HTML_File,Name):

    HTML_File.write("""
<html>
<head>
<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">
<title>
    """)
    HTML_File.write("Tracking PNG's for "+Name)
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
    HTML_File.write("<h1>Tracking for "+Name+"</h1><p/>")


def close_html_file(HTML_File):
    HTML_File.write("""
</body>
</html>""")

if len(sys.argv) <=1:
   sys.exit("Name for plots must be provided on the command line")
else:
    Plot_Name = sys.argv[1]

antennas = read_tracked_antennas()
sv_by_antenna = read_SVs_by_antenna()

HTML_File = open("PNGs.html", "w")

create_html_header(HTML_File, Plot_Name)

(t_min, t_max) = determine_SV_time_range()
t_min = t_min / 1000
t_max = t_max / 1000
output_plot_header(t_min, t_max)

read_Bands_and_create_header(antennas, HTML_File)
read_Bands_and_create_plots(antennas, sv_by_antenna, HTML_File, Plot_Name)

close_html_file(HTML_File)
