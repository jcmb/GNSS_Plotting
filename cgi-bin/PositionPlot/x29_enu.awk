#! /usr/bin/awk 
#
# Converts a LLH file from viewdat (using -x) to
# ENU based on an assumed truth position.
#
# Stuart Riley 3/3/2000
#
BEGIN{

  # PI from st_const.h
  PI = 3.14159265358979323846;


  # Prevent awk from thinking command line arguments are files
  ARGC = 2; 

  # Define the "truth"
  ref_lat = ARGV[2]*PI/180.0;
  ref_lon = ARGV[3]*PI/180.0;
  ref_hgt = ARGV[4];

#  ref_lat =   37.38901944*PI/180.0;
#  ref_lon = -122.03687167*PI/180.0;
#  ref_hgt =   -5.0;

  # Define WGS84 Ellipsoid Parameters
  a = 6378137;
  f = 1 / 298.257223563;
  e2 = 2*f - f^2;

  # Compute Radii of Curvature
  W = sqrt( 1 - e2 * sin(ref_lat)^2 );
  N = a / W;
  M = a * ( 1 - e2 ) / W^3;

  LineNo         = 0;
  FS=",";
  OFS=",";
}

{
########################
# Main processing loop #
########################

#
# Dump the first three lines which just contain text
#
 dlat = $11 * PI/180.0 - ref_lat;
 dlon = $12 * PI/180.0 - ref_lon;
 dhgt = $13            - ref_hgt;

 # Compute Metric Components
 dN = M * dlat;
 dE = N * cos(ref_lat) * dlon;
 dU = dhgt;

 # Finally output the east/north/up position error
 # Stinger NAV-PC in fields 8-10 has E/N/U sigmas
 # print dlat,M,N,W,a,e2;
 # print $1,dE,dN,dU,$5,$6,$7,$8,$9,$10;
 #print out an updated X29 file
 $11 = dN;
 $12 = dE;
 $13 = dU;
 print;

}

