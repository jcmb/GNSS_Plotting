#! /usr/bin/python3
import os, sys
from stat import *
import time
import datetime
 
def baselist(top, callback,timeafter):
    '''recursively descend the directory tree rooted at top,
       calling the callback function for each regular file'''
    dirs=os.listdir(top)

    dirs.sort()

#    dirs=sorted(os.listdir(top), key=lambda s: s.lower())
    print('<table border="1"><tr><th>Base</th><th> Status </th></th>')

    for f in dirs:
        pathname = os.path.join(top, f)
        mode = os.stat(pathname).st_mode
        if S_ISDIR(mode):
            # It's a directory, recurse into it
           visitdir(pathname,f,timeafter)
    print("</table>")
    print("")

def visitdir(path,dirname,timeafter):
#    print 'dir', path, dirname
    Last_Time=-1
    for f in os.listdir(path):
        pathname = os.path.join(path, f)
        mode = os.stat(pathname).st_mode
        if S_ISREG(mode):
            # It's a directory, recurse into it
#              print 'File %s' % pathname
           time = os.stat(pathname).st_mtime 
           if (time > Last_Time) :
               Last_Time =time;
           
           if (time > timeafter) : 
#                  print "File is new
               print('<tr><td>%s</td><td> OK </td></tr>' % dirname)
               return True

               
    if Last_Time != -1 :
        print('<tr><td>%s</td><td> %s %s </td></tr>' % (dirname, datetime.datetime.fromtimestamp(Last_Time),datetime.datetime.fromtimestamp(timeafter)))
    else: 
        print('<tr><td>%s</td><td> No Files </td></tr>' % dirname)
    return False


if __name__ == '__main__':
#   walktree(sys.argv[1], visitfile)
    if len (sys.argv) != 3 :
        print("Robbie.py: ")
        print("")
        print("Usage: <Directory> <Hours old>")
        print("")
        print("Creates a HTML table for directories from the sub directory and the date of the newest file if that file is older than delay hours)")
        quit()

    try:
       delay=(float(sys.argv[2]))
    except:
       print("Error: Delay must be a number")
       quit(1)
 
    timeafter=time.time()-(delay*3600) 
    baselist(sys.argv[1], visitdir, timeafter)
   
