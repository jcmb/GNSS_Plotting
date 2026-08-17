#!/usr/bin/env python3

import glob

for file in glob.glob('*.SNR'):
    print(file[0:-4])
