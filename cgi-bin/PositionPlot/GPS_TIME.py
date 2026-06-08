from datetime import timedelta,datetime,date,tzinfo;
from time import gmtime
from calendar import timegm

ZERO = timedelta(0)
HOUR = timedelta(hours=1)

# A UTC class.

class UTC(tzinfo):
    """UTC"""

    def utcoffset(self, dt):
        return ZERO

    def tzname(self, dt):
        return "UTC"

    def dst(self, dt):
        return ZERO

utc = UTC()


SECONDS_IN_A_HOUR = 3600;
SECONDS_IN_A_DAY  = 24 * SECONDS_IN_A_HOUR;
SECONDS_IN_A_WEEK = 7 * SECONDS_IN_A_DAY;

def GPS_Start(): # Return the Time Stamp, seconds value for the start
    return timegm ([1980,1,6,0,0,0,0]); # 6th of Jan 1980 is GPS 0 in UTC

def  Week_Seconds_To_Time (Week,Secs):
    The_Date = (Week * SECONDS_IN_A_WEEK) + Secs + GPS_Start();
    return The_Date

def  Week_Seconds_To_Unix (Week,Secs):
    The_Date = (Week * SECONDS_IN_A_WEEK) + Secs + GPS_Start()
    return The_Date

def  Week_Seconds_To_MS (Week,Secs):
    The_Date = (Week * SECONDS_IN_A_WEEK) + Secs + GPS_Start()
    return The_Date*1000

def  DateTime_To_Week (The_Date):
    The_Week = The_Date
    The_Week -= GPS_Start()
    The_Week = The_Week/SECONDS_IN_A_WEEK
    The_Week = int(The_Week)
    return The_Week


def  DateTime_To_Seconds_Of_Week (The_Date):
    The_Seconds = The_Date - GPS_Start()
    The_Seconds = The_Seconds % SECONDS_IN_A_WEEK
    return The_Seconds


def Current_Week():
#   The_Week = int(((datetime.utcnow() - GPS_Start()).total_seconds())/SECONDS_IN_A_WEEK)
    return DateTime_To_Week(timegm(gmtime())) # Ignores leap seconds

if __name__ == "__main__":
    print("")
    print("GPS Week 0")

    print(GPS_Start())
    Start = GPS_Start()
    print(Start)

    print(Week_Seconds_To_Unix (0,0))
    print(Week_Seconds_To_MS (0,0))
    print(Week_Seconds_To_Time (0,0))
    Test_Date = Week_Seconds_To_Time (0,0)
    print(DateTime_To_Week(Test_Date))
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1")
    print(Week_Seconds_To_Unix (1,0))
    print(Week_Seconds_To_MS (1,0))
    print(Week_Seconds_To_Time (1,0))
    Test_Date = Week_Seconds_To_Time (1,0)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 3600 Seconds")
    print(Week_Seconds_To_Unix (1,3600))
    print(Week_Seconds_To_Time (1,3600))
    Test_Date = Week_Seconds_To_Time (1,3600)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 0, 0.5 Seconds")
    print(Week_Seconds_To_Time (0,0.5))
    print(Week_Seconds_To_Unix (0,0.5))
    print(Week_Seconds_To_MS (0,0.5))
    Test_Date = Week_Seconds_To_Time (0,0.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 0.5 Seconds")
    print(Week_Seconds_To_Unix (1,0.5))
    print(Week_Seconds_To_MS (1,0.5))
    print(Week_Seconds_To_Time (1,0.5))
    Test_Date = Week_Seconds_To_Time (1,0.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 3600.5 Seconds")
    print(Week_Seconds_To_Unix (1,3600.5))
    print(Week_Seconds_To_Time (1,3600.5))
    Test_Date = Week_Seconds_To_Time (1,3600.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date) ,DateTime_To_Seconds_Of_Week(Test_Date)))
    print("")
    print(Current_Week())
