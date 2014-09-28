__author__ = 'Brad'

import datetime
import sys
from ITADao import ITADao

print "Enter your origin ie. ORD"
origin = sys.stdin.readline().strip('\n')

print "Enter in your destinations separated by a comma. ie. HKG,PEK"
destinations = sys.stdin.readline().strip('\n')
destinations = destinations.split(',')

print "Enter the starting date of the date range in the format of 2014-09-20"
start_date = sys.stdin.readline().strip('\n')
start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d")

print "Enter the ending date of the date range in the format of 2014-12-31"
end_date = sys.stdin.readline().strip('\n')
end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d")

print "Enter the minimum trip length"
min_length = sys.stdin.readline().strip('\n')

print "Enter the maximum trip length"
max_length = sys.stdin.readline().strip('\n')


for dest in destinations:
    dao = ITADao(origin, dest, start_date, end_date, min_length, max_length)
    trips = dao.get_trip_data()
    trips = trips.find_best_value()
    trips = trips.find_cheapest_trips()
    tlist = trips.get_trips()

    for trip in tlist:
        trip.to_string()


