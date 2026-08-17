#!/usr/bin/env python3

import calendar
from datetime import datetime, date

SECONDS_IN_A_HOUR = 3600
SECONDS_IN_A_DAY = 24 * SECONDS_IN_A_HOUR
SECONDS_IN_A_WEEK = 7 * SECONDS_IN_A_DAY

GPS_EPOCH = date(1980, 1, 6)
GPS_EPOCH_UNIX = calendar.timegm(GPS_EPOCH.timetuple())


def GPS_Start():
    return datetime(1980, 1, 6)


def Week_Seconds_To_Time(Week, Secs):
    return datetime.utcfromtimestamp(Week_Seconds_To_Unix(Week, Secs))


def Week_Seconds_To_Unix(Week, Secs):
    return (Week * SECONDS_IN_A_WEEK) + Secs + GPS_EPOCH_UNIX


def Week_Seconds_To_MS(Week, Secs):
    return Week_Seconds_To_Unix(Week, Secs) * 1000


def DateTime_To_Week(The_Date):
    The_Week = The_Date - GPS_Start()
    return int(The_Week.total_seconds() / SECONDS_IN_A_WEEK)


def DateTime_To_Seconds_Of_Week(The_Date):
    The_Seconds = The_Date - GPS_Start()
    return The_Seconds.total_seconds() % SECONDS_IN_A_WEEK


def Current_Week():
    return DateTime_To_Week(datetime.utcnow())


if __name__ == "__main__":
    print("")
    print("GPS Week 0")
    print(GPS_Start())
    print(GPS_EPOCH_UNIX)
    print(Week_Seconds_To_Unix(0, 0))
    print(Week_Seconds_To_MS(0, 0))
    print(Week_Seconds_To_Time(0, 0))
    Test_Date = Week_Seconds_To_Time(0, 0)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1")
    print(Week_Seconds_To_Unix(1, 0))
    print(Week_Seconds_To_MS(1, 0))
    print(Week_Seconds_To_Time(1, 0))
    Test_Date = Week_Seconds_To_Time(1, 0)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 3600 Seconds")
    print(Week_Seconds_To_Unix(1, 3600))
    print(Week_Seconds_To_Time(1, 3600))
    Test_Date = Week_Seconds_To_Time(1, 3600)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 0, 0.5 Seconds")
    print(Week_Seconds_To_Time(0, 0.5))
    print(Week_Seconds_To_Unix(0, 0.5))
    print(Week_Seconds_To_MS(0, 0.5))
    Test_Date = Week_Seconds_To_Time(0, 0.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 0.5 Seconds")
    print(Week_Seconds_To_Unix(1, 0.5))
    print(Week_Seconds_To_MS(1, 0.5))
    print(Week_Seconds_To_Time(1, 0.5))
    Test_Date = Week_Seconds_To_Time(1, 0.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))

    print("")
    print("GPS Week 1, 3600.5 Seconds")
    print(Week_Seconds_To_Unix(1, 3600.5))
    print(Week_Seconds_To_Time(1, 3600.5))
    Test_Date = Week_Seconds_To_Time(1, 3600.5)
    print("{0}:{1}".format(DateTime_To_Week(Test_Date), DateTime_To_Seconds_Of_Week(Test_Date)))
    print("")
    print(Current_Week())
