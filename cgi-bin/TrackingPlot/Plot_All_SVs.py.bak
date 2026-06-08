#!/usr/bin/python

import re
import sys

def output_plot_header (min,max):
    print """
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
    """

    print "set xrange[{}:{}]".format(min,max)


def output_plot (System,Band_Name,Tracking,Field,SVs,HTML_File,Plot_Name):
#    print SVs
    HTML_File.write('<h3>{} {}{}</h3>'.format(System,Band_Name,Tracking))
    HTML_File.write('<a name="{}-{}-{}"/>'.format(System,Band_Name,Tracking))
    HTML_File.write('<img src="{}-{}-{}.SNRs.png"'.format(System,Band_Name,Tracking))
    HTML_File.write('alt="{}-{}-{}.SNRs.png">'.format(System,Band_Name,Tracking))
    HTML_File.write("<p/><p/>\n")
    print ""
    print 'set output "{}-{}-{}.SNRs.png"'.format(System,Band_Name,Tracking)
    print 'set title "{} {} {} {} SNRs"'.format(Plot_Name,System,Band_Name,Tracking)
    print ""
    print "plot \\"
    first = True
    for SV in SVs:
       if first:
            first=False
       else:
          print  ",\\"
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\"".format(System,SV,Field,SV),

    print ""

def read_Bands_and_create_plots(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name):
    Bands_file=open("Tracked.Bands","r")
    for Band in Bands_file:
        Band=Band.strip()
        m=re.search('(.*)-(.*)-(.*)',Band)
#        print m.group(1),m.group(2),m.group(3)

        if m:
            Sys=m.group(1).upper()
            Band=m.group(2).upper()
            Tracked=m.group(3).upper()
            if Sys=="GPS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(Sys,Band,Tracked,4,GPS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="E":
                        output_plot(Sys,Band,Tracked,6,GPS_SVs,HTML_File,Plot_Name)
                    elif Tracked=="CS":
                        output_plot(Sys,Band,Tracked,8,GPS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L2 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="IQ":
                        output_plot(Sys,Band,Tracked,10,GPS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GPS L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GPS Band: " + Band)


            elif Sys=="GLONASS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(Sys,Band,Tracked,4,GLONASS_SVs,HTML_File,Plot_Name)
                    elif Tracked=="P":
                        output_plot(Sys,Band,Tracked,6,GLONASS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GLONASS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="CA":
                        output_plot(Sys,Band,Tracked,8,GLONASS_SVs,HTML_File,Plot_Name)
                    elif Tracked=="P":
                        output_plot(Sys,Band,Tracked,10,GLONASS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GLONASS L2 Tracked: " + Tracked)

                elif Band=="G3":
                    if Tracked=="G3_PD":
#                        output_plot(Sys,Band,Tracked,12,GLONASS_SVs,HTML_File,Plot_Name)
                        pass
                    else:
                        sys.exit("Internal Error, Unknown GLONASS G3 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GLONASS Band: " + Band)


            elif Sys=="SBAS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(Sys,Band,Tracked,4,SBAS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown SBAS L1 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="I":
                        output_plot(Sys,Band,Tracked,6,SBAS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown SBAS L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown SBAS Band: " + Band)

            elif Sys=="GAL":
                if Band=="L1":
                    if Tracked=="MBOC_1_1_PD":
                        output_plot(Sys,Band,Tracked,4,GAL_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL L1 Tracked: " + Tracked)
                elif Band=="E5AB":
                    if Tracked=="ALTBOC_C_PD":
                        output_plot(Sys,Band,Tracked,6,GAL_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL E5AB Tracked: " + Tracked)
                elif Band=="E5B":
                    if Tracked=="BPSK_PD":
                        output_plot(Sys,Band,Tracked,8,GAL_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL E5B Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="BPSK_PD":
                        output_plot(Sys,Band,Tracked,10,GAL_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown GAL L5 Tracked: " + Tracked)
                else:
                    sys.exit("Internal Error, Unknown GAL Band: " + Band)

            elif Sys=="BDS":
                if Band=="B1_E2":
                    if Tracked=="BPSK2_B1":
                        output_plot(Sys,Band,Tracked,4,BDS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS L1 Tracked: " + Tracked)
                elif Band=="E5B":
                    if Tracked=="BPSK2_B2":
                        output_plot(Sys,Band,Tracked,6,BDS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS L5 Tracked: " + Tracked)
                elif Band=="B3":
                    if Tracked=="BPSK2_B3":
                        output_plot(Sys,Band,Tracked,8,BDS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown BDS B3 Tracked: " + Tracked)
            elif Sys=="QZSS":
                if Band=="L1":
                    if Tracked=="CA":
                        output_plot(Sys,Band,Tracked,4,QZSS_SVs,HTML_File,Plot_Name)
                    elif Tracked=="BOC_1_1_PD":
                        output_plot(Sys,Band,Tracked,6,QZSS_SVs,HTML_File,Plot_Name)
                    elif Tracked=="SAIF":
                        output_plot(Sys,Band,Tracked,8,QZSS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown QZSS L1 Tracked: " + Tracked)
                elif Band=="L2":
                    if Tracked=="CS":
                        output_plot(Sys,Band,Tracked,10,QZSS_SVs,HTML_File,Plot_Name)
                    else:
                        sys.exit("Internal Error, Unknown QZSS L2 Tracked: " + Tracked)
                elif Band=="L5":
                    if Tracked=="IQ":
                        output_plot(Sys,Band,Tracked,12,QZSS_SVs,HTML_File,Plot_Name)
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
    min=1000000000000000
    min=1000000000000000
    max=-2

    SVs_file=open("Tracked.SVs","r")
    for SV in SVs_file:
        SV=SV.strip()
#        print SV
        SV_File=open(SV+".SNR-SV","r")
        first_line=SV_File.readline()
        for line in SV_File:
            last_line=line

#        print first_line
        m=re.search('(.*?),.*',first_line)
        if m:
            if float(m.group(1))<min:
                min=float(m.group(1))


#        print last_line
        m=re.search('(.*?),.*',last_line)
        if m:
            if float(m.group(1))>max:
                max=float(m.group(1))

        SV_File.close()

#        print SV, min,max
    return(min,max)



    max=-2

    SVs_file=open("Tracked.SVs","r")
    for SV in SVs_file:
        SV=SV.strip()
#        print SV
        SV_File=open(SV+".SNR-SV","r")
        first_line=SV_File.readline()
        for line in SV_File:
            last_line=line

#        print first_line
        m=re.search('(.*?),.*',first_line)
        if m:
            if float(m.group(1))<min:
                min=float(m.group(1))


#        print last_line
        m=re.search('(.*?),.*',last_line)
        if m:
            if float(m.group(1))>max:
                max=float(m.group(1))

        SV_File.close()

#        print SV, min,max
    return(min,max)


def read_SVs(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs):
    SVs_file=open("Tracked.SVs","r")
    for SV in SVs_file:
        SV=SV.strip()
        m=re.search('(.*)-(.*)',SV)
        if m:
            Sys=m.group(1).upper()
            SV=int(m.group(2))

#            print Sys,SV

            if Sys=="GPS":
                GPS_SVs.append(SV)
            elif Sys=="GLONASS":
                GLONASS_SVs.append(SV)
            elif Sys=="SBAS":
                SBAS_SVs.append(SV)
            elif Sys=="GAL":
                GAL_SVs.append(SV)
            elif Sys=="BDS":
                BDS_SVs.append(SV)
            elif Sys=="QZSS":
                QZSS_SVs.append(SV)
            else:
                sys.exit("Internal Error, Unknown SV Type: " + Sys)


        else:
            sys.exit("Internal Error, could not decode Tracked SVs: " + SV)

    GPS_SVs.sort()
    GLONASS_SVs.sort()
    SBAS_SVs.sort()
    GAL_SVs.sort()
    BDS_SVs.sort()
    QZSS_SVs.sort()
    SVs_file.close()


def read_Bands_and_create_header(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name):
    HTML_File.write('<h2>Bands Tracked</h2>')
    Bands_file=open("Tracked.Bands","r")
    for Band in Bands_file:
        Band=Band.strip()
        m=re.search('(.*)-(.*)-(.*)',Band)
        if m:
            System=m.group(1).upper()
            Band_Name=m.group(2).upper()
            Tracked=m.group(3).upper()
            HTML_File.write('<a href="#{}-{}-{}">'.format(System,Band_Name,Tracked))
            HTML_File.write('{} {} {}'.format(System,Band_Name,Tracked))
            HTML_File.write('</a><br>')
    HTML_File.write('<p/>')
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
    Plot_Name=sys.argv[1]

GPS_SVs=[]
GLONASS_SVs=[]
SBAS_SVs=[]
GAL_SVs=[]
BDS_SVs=[]
QZSS_SVs=[]

HTML_File=open("PNGs.html","w")


create_html_header(HTML_File,Plot_Name)

read_SVs(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs)

(min,max)=determine_SV_time_range()
min=min/1000
max=max/1000
output_plot_header (min,max)

#print GPS_SVs
#print GLONASS_SVs
#print SBAS_SVs
#print GAL_SVs
#print BDS_SVs

read_Bands_and_create_header(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name)
read_Bands_and_create_plots(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name)

close_html_file(HTML_File)
