__author__ = 'Brad'

import datetime
import threading
import sys
from ITADao import ITADao
from Trip import Trip
from Flight import Flight

class ITAThread (threading.Thread):
    def __init__(self, dest, start_date, end_date, results):
        threading.Thread.__init__(self)
        self.results = results
        self.dest = dest
        self.start_date = start_date
        self.end_date = end_date

    def run(self):
        ita_dao = ITADao(self.dest, self.start_date, self.end_date)
        calendar = ita_dao.get_calendar_data()
        cheapest_dates = calendar.find_cheapest_rt()
        threads = []
        for dates in cheapest_dates:
            t = ITATripThread(dates[0], dates[1], calendar.get_session_id(), results, ita_dao)
            t.start()
            threads.append(t)

        for t in threads:
            t.join()


class ITATripThread (threading.Thread):
    def __init__(self, outbound, inbound, session, results, ita_dao):
        threading.Thread.__init__(self)
        self.results = results
        self.outbound = outbound
        self.inbound = inbound
        self.session = session
        self.ita_dao = ita_dao

    def run(self):
        ita_trips = self.ita_dao.get_trips(self.outbound, self.inbound, self.session)
        trips = ita_trips.find_trips_below_ppm(0.06)
        self.results.append(trips)

print "Enter in your destinations separated by a comma. ie. HKG,PEK"
destinations = sys.stdin.readline().strip('\n')
destinations = destinations.split(',')

print "Enter the starting date of the date range in the format of 2014-09-20"
start_date = sys.stdin.readline().strip('\n')
start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d")

print "Enter the ending date of the date range in the format of 2014-12-31"
end_date = sys.stdin.readline().strip('\n')
end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d")


for dest in destinations:
    amt_of_days = (end_date-start_date).days
    print amt_of_days
    searches_needed = amt_of_days/30
    print searches_needed

    results = []
    threads = []
    start = start_date
    end = start_date + datetime.timedelta(days=29)
    for x in range(0, searches_needed):
        t = ITAThread(dest, start.strftime('%Y-%m-%d'), end.strftime('%Y-%m-%d'), results)
        t.start()
        threads.append(t)
        start = end + datetime.timedelta(days=1)
        end = start + datetime.timedelta(days=29)

    rem = amt_of_days % 30
    if rem != 0:
        end = start + datetime.timedelta(days=rem-1)
        t = ITAThread(dest, start.strftime('%Y-%m-%d'), end.strftime('%Y-%m-%d'), results)
        t.start()
        threads.append(t)

    for t in threads:
        t.join()

    for trips in results:
        for trip in trips:
            trip.to_string()

