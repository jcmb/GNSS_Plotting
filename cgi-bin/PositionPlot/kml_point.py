#!/usr/bin/env python3
import sys

if len(sys.argv) != 5:
    sys.stderr.write('Usage: ' + sys.argv[0] + ' <Point Name> <Lat> <Long> <Height>\n')
    sys.stderr.write('\n')
    sys.stderr.write('Lat Long are in decimal degrees\n')
    sys.stderr.write('writes a file, <Point Name>.kml with a single point that is the llh from the command line\n')
    sys.exit(1)

import simplekml

kml = simplekml.Kml()
kml.newpoint(name=sys.argv[1], coords=[(sys.argv[3],sys.argv[2],sys.argv[4])])
kml.save(sys.argv[1]+".kml")
