#!/usr/bin/python3
#GNSS_TRUTH.py
import argparse
import os
import sqlite3
import sys

parser = argparse.ArgumentParser(description='Return information for a point.')
parser.add_argument("Pt_Id", help="The Point ID that you want information on")
args = parser.parse_args()

if args.Pt_Id in ("", "-1"):
    sys.exit(1)

script_dir = os.path.dirname(os.path.abspath(__file__))
inc_candidates = [
    os.path.join(script_dir, "db.TRUTH.inc.py"),
    "/mnt/GPS_Admin/cgi-bin/PositionPlot/db.TRUTH.inc.py",
]
inc_path = next((path for path in inc_candidates if os.path.isfile(path)), None)
if inc_path is None:
    sys.exit(1)

exec(compile(open(inc_path, "rb").read(), inc_path, "exec"))


class DB_Class:

    def __init__(self):
        self.conn = None

    def open(self):
        db_path = databaseFile()
        if not os.path.isfile(db_path):
            sys.exit(1)
        try:
            self.conn = sqlite3.connect(db_path)
        except sqlite3.Error:
            sys.exit(1)

        self.conn.row_factory = sqlite3.Row
        self.GNSS = self.conn.cursor()

    def read_GNSS_Settings(self, Pt_Id):
        query = 'SELECT * FROM GNSS_Truth where Pt_Id="' + str(Pt_Id) + '"'
        self.GNSS.execute(query)
        row = self.GNSS.fetchone()

        if row:
            self.Lat = row["Lat"]
            self.Long = row["Long"]
            self.Height = row["Height"]
            self.Pt_Id = row["Pt_Id"]
            self.Solution = row["Solution"]
            return True
        return False


DB = DB_Class()
DB.open()
if DB.read_GNSS_Settings(args.Pt_Id.upper()):
    print("Lat=" + str(DB.Lat) + ";Long=" + str(DB.Long) + ";Height=" + str(DB.Height) + ";Sol=" + str(DB.Solution))
    sys.exit(0)
sys.exit(1)
