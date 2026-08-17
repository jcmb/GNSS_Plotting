#!/usr/bin/env python3

import glob

for file in glob.glob('*.SNR-SV'):
    print(file[0:-7])
