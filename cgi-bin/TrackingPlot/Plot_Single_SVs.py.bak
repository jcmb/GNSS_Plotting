#!/usr/bin/python

import re
import sys

from GNSS_Decls import GPS_L2CS, GPS_L5

def output_plot_header (min,max):
    print """
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

    """
    print "set xrange[{}:{}]".format(min,max)



def output_plot (System,SV,HTML_File,Plot_Name):
#    print SVs
    HTML_File.write('<a name="{}-{}">'.format(System,SV))
    HTML_File.write('<img src="{}-{}.SNR.png"'.format(System,SV))
    HTML_File.write('alt="{}-{}.SNR.png">'.format(System,SV))
    HTML_File.write("<p/><p/>\n")
    print ""
    print 'set output "{}-{}.SNR.png"'.format(System,SV)
    print 'set title "{} {} {} SNRs"'.format(Plot_Name,System,SV)
    print ""
    print "plot \\"
    if System=="GPS":

       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"L2 E")
       if GPS_L2CS[SV]:
           print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,8,"L2 CS")
       if GPS_L5[SV]:
           print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,10,"L5 IQ")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,12,"Exp L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,13,"Exp L2 E")
       if GPS_L2CS[SV]:
           print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,14,"Exp L2 CS")
       if GPS_L5[SV]:
           print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,15,"Exp L5 IQ")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)

    elif System=="GLONASS":
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"L1 P")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,8,"L2 CA")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,10,"L2 P")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,12,"Exp L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,13,"Exp L1 P")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,14,"Exp L2 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,15,"Exp L2 P")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)
    elif System=="GAL":
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"E1")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"AltBoc")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)
    elif System=="BDS":
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"B1")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"B2")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)
    elif System=="SBAS":
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"L5 IQ")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)
    elif System=="QZSS":
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,4,"L1 C/A")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,6,"L1 BOC_1_1_PD")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,8,"L1 SAIF")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,10,"L2 CS")
       print "'{}-{}.SNR-SV' using ($1/1000):(${}) title \"{}\",\\".format(System,SV,13,"L5 IQ")
       print "'{}-{}.SNR-SV' using ($1/1000):($2) title \"Elevation\" smooth bezier axis x1y2".format(System,SV)
    else:
        sys.exit("Internal Error, Unknown SV Type: " + Sys)

    print ""

def create_Sys_Plots(Sys,SVs,HTML_File,Name):
    for SV in SVs:
        output_plot(Sys,SV,HTML_File,Name)

def create_plots(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name):
    create_Sys_Plots("GPS",GPS_SVs,HTML_File,Plot_Name);
    create_Sys_Plots("GLONASS",GLONASS_SVs,HTML_File,Plot_Name)
    create_Sys_Plots("SBAS",SBAS_SVs,HTML_File,Plot_Name)
    create_Sys_Plots("GAL",GAL_SVs,HTML_File,Plot_Name)
    create_Sys_Plots("BDS",BDS_SVs,HTML_File,Plot_Name)
    create_Sys_Plots("QZSS",QZSS_SVs,HTML_File,Plot_Name)

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

def create_html_header(HTML_File,Name):

    HTML_File.write("""
<html>
<head>
<link rel="stylesheet" type="text/css" href="/css/tcui-styles.css">
<title>
    """)
    HTML_File.write("Single SV Tracking PNG's for "+Name)
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
    HTML_File.write("<h1>Single SV Tracking for "+Name+"</h1><p/>")


def close_html_file(HTML_File):
    HTML_File.write("""
</body>
</html>""")


def create_html_Single_TOC(HTML_File,System,SVs):
    HTML_File.write("<bold>{}: </bold>".format(System)),
    for SV in SVs:
        HTML_File.write('<a href="#{}-{}">{}</a>\n'.format(System,SV,SV))
    HTML_File.write("<br/>")



def create_html_TOC(HTML_File,GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs):
    if GPS_SVs:
        create_html_Single_TOC(HTML_File,"GPS",GPS_SVs)
    if GLONASS_SVs:
        create_html_Single_TOC(HTML_File,"GLONASS",GLONASS_SVs)
    if GAL_SVs:
        create_html_Single_TOC(HTML_File,"GAL",GAL_SVs)
    if BDS_SVs:
        create_html_Single_TOC(HTML_File,"BDS",BDS_SVs)
    if SBAS_SVs:
        create_html_Single_TOC(HTML_File,"SBAS",SBAS_SVs)
    if QZSS_SVs:
        create_html_Single_TOC(HTML_File,"QZSS",QZSS_SVs)



def determine_SV_time_range():
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

HTML_File=open("PNGs_SVs.html","w")


create_html_header(HTML_File,Plot_Name)

read_SVs(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs)

(min,max)=determine_SV_time_range()
min=min/1000
max=max/1000

output_plot_header (min,max)

create_html_TOC(HTML_File,GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs)

#print GPS_SVs
#print GLONASS_SVs
#print SBAS_SVs
#print GAL_SVs
#print BDS_SVs

create_plots(GPS_SVs,GLONASS_SVs,SBAS_SVs,GAL_SVs,BDS_SVs,QZSS_SVs,HTML_File,Plot_Name)

close_html_file(HTML_File)
