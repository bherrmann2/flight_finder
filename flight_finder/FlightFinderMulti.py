__author__ = 'Nick Ruiz'

import datetime
import sys
from ITADao import ITADao

#print "Enter your origin ie. ORD"
#origin = sys.stdin.readline().strip('\n')
origin = 'SEA'

#print "Enter in your destinations separated by a comma. ie. HKG,PEK"
#destinations = sys.stdin.readline().strip('\n')
destinations = 'NYC,PHL'

#print "Enter the starting date of the date range in the format of 2014-09-20"
#start_date = sys.stdin.readline().strip('\n')
#start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d")
start_date = '2014-10-30'

#print "Enter the ending date of the date range in the format of 2014-12-31"
#end_date = sys.stdin.readline().strip('\n')
#end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d")
end_date = '2014-11-25'

#print "Enter the minimum trip length"
#min_length = sys.stdin.readline().strip('\n')

#print "Enter the maximum trip length"
#max_length = sys.stdin.readline().strip('\n')

dao = ITADao()
dao.add_specific_flight(origins=origin, destinations=destinations, depart_date=start_date, date_minus=1, date_plus=1, route_language='X:DEN')
dao.add_specific_flight(origins=destinations, destinations='PHX', depart_date='2014-11-01', date_minus=1, date_plus=1, command_line='alliance oneworld')
dao.add_specific_flight(origins='PHX', destinations=origin, depart_date=end_date, date_minus=1, date_plus=1, command_line='alliance oneworld')

print dao.flight_requests.flights
trips = dao.get_trip_data()
trips = trips.find_best_value()
trips = trips.find_cheapest_trips()
tlist = trips.get_trips()
 
for trip in tlist:
    trip.to_string()
        
