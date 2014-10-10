__author__ = 'Brad Herrmann'

import json
import requests
import datetime
import threading
from ITACalendar import ITACalendar
from ITATrips import ITATrips
from FlightRequest import FlightRequest, FlightRequestCollection
from collections import OrderedDict

class ITARequest(object):
    """
    Handles XmlHttpRequests for ITA matrix. Use this for some fault tolerance.
    Sometimes ITA returns this garbage:
    {"error":{"message":"QPX capacity exceeded.","code":"qpxBusy","resultId":"m8MSFAUAaueRBBCFK0Kog0","type":"internal"}}
    """
    def __init__(self, timeout=datetime.timedelta(minutes=1)):
        # Make sure it's a valid timeout
        assert type(timeout) is datetime.timedelta, "Must specify a valid timeout"
        self.timeout = timeout
    
    def post_request(self, url, payload, headers):
        start_time = datetime.datetime.now()
        curr_time = start_time
        elapsed_time = curr_time - start_time
        success = False
        
        data = None
        while not success and elapsed_time < self.timeout:
            print "Elapsed time: {0} seconds".format(elapsed_time.seconds)
            page = requests.post(url, data=payload, headers=headers)
            text = page.text[4:]
            print text
            data = json.loads(text)
            
            if 'error' in data:
                assert data['error']['code'] == 'qpxBusy', "Unrecoverable error: {0}".format(data['error']['message'])
            else:
                success = True
            
            # Get the current time
            curr_time = datetime.datetime.now()
            elapsed_time = curr_time - start_time
        
        return data

"""
Retrieves the trip information from ITA Software
"""
class ITADao:

    headers = \
    {
        "Content-Type" : "application/x-www-form-urlencoded; charset=UTF-8",
        "Cookie" : '__utma=269716137.1963755597.1368591497.1368846168.1369958808.3; __utma=241137183.308417330.1368591501.1403974868.1403991047.140; __utmz=241137183.1402970608.133.6.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); searchFormState=%7B%22version%22%3A%220.7.20120825.1%22%2C%22json%22%3A%22%7B%5C%22mode%5C%22%3A%7B%5C%22date%5C%22%3A%5C%22calendar%5C%22%2C%5C%22flightSelection%5C%22%3A%5C%22slice%5C%22%2C%5C%22flightView%5C%22%3A%5C%22slice%5C%22%2C%5C%22pageFlow%5C%22%3A%5C%22calendar%5C%22%2C%5C%22trip%5C%22%3A%5C%22rt%5C%22%2C%5C%22calendarRange%5C%22%3A%5C%2230day%5C%22%7D%2C%5C%22searchForm%5C%22%3A%7B%5C%22mode%5C%22%3A%5C%22advanced%5C%22%2C%5C%22defaults%5C%22%3A%7B%5C%22multiCityRows%5C%22%3A2%7D%2C%5C%22awards%5C%22%3A%5C%22noawards%5C%22%2C%5C%22options%5C%22%3A%7B%5C%22showRoutingCodes%5C%22%3Atrue%2C%5C%22pax%5C%22%3A%5C%22simple%5C%22%7D%7D%7D%22%7D; pricePerMile=%7B%22showControl%22%3Atrue%2C%22showPrice%22%3Atrue%7D; mode.flight=%7B%22view%22%3A%22trip%22%2C%22selection%22%3A%22trip%22%7D; PREF="ID=ddab770e84ffbd166c060d8402d1da5ced52210c7cc1eebfec1ba7ab84841a404416a0bfbf08cb7facfb49969cb56fbd912fb4fc80412f15b2456abb34a0e50f:TM=1403972269:S=052ph5Y8jci3Qu3t"; __utmc=241137183; __utmb=241137183.11.10.1403991047',
        "Cache-Control" : 'no-cache',
        "Content-Length" : '0',
    }

    host = "http://matrix.itasoftware.com"

    path = "/xhr/shop/search"

    url = host + path

    def __init__(self):
        self.flight_requests = FlightRequestCollection()
        
    def add_specific_flight(self, origins, destinations, depart_date, date_minus=0, date_plus=0, route_language=None, command_line=None):
        self.flight_requests.add_single_flight(origins, destinations, depart_date, date_minus, date_plus, route_language, command_line)
        self.search_type = 'specific'
        
    def set_calendar_query(self, origin, dest, start, end, min_length, max_length):
        self.origin = origin
        self.dest = dest
        self.start_date = start
        self.end_date = end
        self.min_length = min_length
        self.max_length = max_length
        self.search_type = 'calendar'
        
    def get_trip_data(self):
        if self.search_type == 'calendar':
            return self.get_calendar_trip_data()
        elif self.search_type == 'specific':
            return self.get_specific_trip_data()
        else:
            print 'Whoops'
            return None
        
    def get_specific_trip_data(self):
        
        threads = []
        trips = []
        
        print self.flight_requests.to_json()
        t = MultiDestinationRequestThread(self.flight_requests, trips)
        t.start()
        threads.append(t)
        
        for t in threads:
            t.join()

        #combine all the returned trip data from all the threads
        ita_trips = ITATrips()
        for trip_data in trips:
            ita_trips._add_trips(trip_data)

        return ita_trips

    """
    Gets the trip data from ITA for the destination and date range
    """
    def get_calendar_trip_data(self):
        #breaks up the date in range into sections of 30 days each.
        #this is done because ITA doesn't handle chunks larger than 30 days each that well
        amt_of_days = (self.end_date-self.start_date).days
        searches_needed = amt_of_days/30 # TODO: if the search is less than 30 days, this doesn't work.
        months = []
        threads = []
        start = self.start_date
        end = self.start_date + datetime.timedelta(days=29)

        #creates a thread that requests a calendar for each 30 day chunk
        for x in range(0, searches_needed):
            t = CalendarRequestThread(self.origin, self.dest, start.strftime('%Y-%m-%d'), end.strftime('%Y-%m-%d'), self.min_length, self.max_length, months)
            t.start()
            threads.append(t)
            start = end + datetime.timedelta(days=1)
            end = start + datetime.timedelta(days=29)

        #creates a thread for the remainder if the date range is not divisible by 30
        rem = amt_of_days % 30
        if rem != 0:
            end = start + datetime.timedelta(days=rem-1)
            t = CalendarRequestThread(self.origin, self.dest, start.strftime('%Y-%m-%d'), end.strftime('%Y-%m-%d'), self.min_length, self.max_length, months)
            t.start()
            threads.append(t)

        #blocks until the threads finish
        for t in threads:
            t.join()

        threads = []
        trips = []
        #goes through each calendar retrieved
        for calendar in months:
            #only gets the cheapest dates in the calendar since those most likely have the best deal and to limit the
            #request count to appear more human
            cheapest_dates = calendar.find_cheapest_rt()
            for dates in cheapest_dates:
                #create a separate thread that requests the trips for the cheapest dates
                t = TripRequestThread(self.origin, self.dest, dates[0], dates[1], self.start_date.strftime('%Y-%m-%d'), self.end_date.strftime('%Y-%m-%d'), self.min_length, self.max_length, calendar.get_session_id(), trips)
                t.start()
                threads.append(t)

        for t in threads:
            t.join()

        #combine all the returned trip data from all the threads
        ita_trips = ITATrips()
        for trip_data in trips:
            ita_trips._add_trips(trip_data)

        return ita_trips
    
class MultiDestinationRequestThread(threading.Thread):
    """
    Thread that handles the request/response for multi-destination searches from ITA
    """
    def __init__(self, flight_requests, results):
        threading.Thread.__init__(self)
        self.flight_requests = flight_requests
        self.results = results
        
    def run(self):
        trips = self.__get_trip_data()
        self.results.append(trips)
        
    def __get_trip_data(self):
        summarizers = ["carrierStopMatrix", "currencyNotice", "solutionList", "itineraryPriceSlider", "itineraryCarrierList", "itineraryDepartureTimeRanges", "itineraryArrivalTimeRanges", "durationSliderItinerary", "itineraryOrigins", "itineraryDestinations", "itineraryStopCountList", "warningsItinerary"]
        commands = OrderedDict()
        commands['name'] = 'specificDates'
        commands['summarizers'] = '%2C'.join(summarizers)
        commands['format'] = 'JSON'
        commands['inputs'] = json.dumps(self.flight_requests.to_json())
        
        payload = '&'.join(['{0}={1}'.format(key,value) for key, value in commands.iteritems()])
            
        request = ITARequest()
        data = request.post_request(ITADao.url, payload, ITADao.headers)
        #page = requests.post(ITADao.url, data=payload, headers=ITADao.headers)

        try:
            flights = data['result']['solutionList']['solutions']
            return flights
        except KeyError:
            print "Error. Couldn't get trip info"
            return []

class CalendarRequestThread (threading.Thread):
    """
    Thread that handles the request/response for the calendar data from ITA
    """
    #needs to be refactored. too many args
    def __init__(self, origin, dest, start_date, end_date, min_length, max_length, results):
        threading.Thread.__init__(self)
        self.results = results
        self.origin = origin
        self.dest = dest
        self.start_date = start_date
        self.end_date = end_date
        self.min_length = min_length
        self.max_length = max_length

    def run(self):
        calendar = self.__get_calendar_data()
        self.results.append(calendar)

    def __get_calendar_data(self):
        """
        gets the calendar data from ITA
        """
        payload = "name=calendar&summarizers=currencyNotice%2CovernightFlightsCalendar%2CitineraryStopCountList%2CitineraryCarrierList%2Ccalendar&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22"+self.origin+"%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22"+self.dest+"%22%5D%2C%22destinationPreferCity%22%3Afalse%7D%2C%7B%22destinations%22%3A%5B%22"+self.origin+"%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22"+self.dest+"%22%5D%2C%22originPreferCity%22%3Afalse%7D%5D%2C%22startDate%22%3A%22"+self.start_date+"%22%2C%22layover%22%3A%7B%22max%22%3A"+self.max_length+"%2C%22min%22%3A"+self.min_length+"%7D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22"+self.end_date+"%22%7D"
        print 'get_calendar_data', payload
        page = requests.post(ITADao.url, data=payload, headers=ITADao.headers)
        text = page.text[4:]
        print text
        data = json.loads(text)
        return ITACalendar(data)


"""
Thread that handles the request/response for the Trip data from ITA
"""
class TripRequestThread (threading.Thread):
    #this needs to be refactored. Too many args
    def __init__(self, origin, dest, outbound, inbound, start, end, min_length, max_length, session, results):
        threading.Thread.__init__(self)
        self.results = results
        self.outbound = outbound
        self.inbound = inbound
        self.session = session
        self.dest = dest
        self.origin = origin
        self.start_date = start
        self.end_date = end
        self.min_length = min_length
        self.max_length = max_length

    def run(self):
        trips = self.get_trips(self.outbound, self.inbound, self.session)
        self.results.append(trips)


    """
    Gets the RT flights for the particular dates
    """
    def get_trips(self, leave, ret, session):
        #need to get the trip length from the calendar and put in max and min
        payload = 'name=calendarFollowup&session=' + session + '&summarizers=carrierStopMatrix%2CcurrencyNotice%2CsolutionList%2CitineraryPriceSlider%2CitineraryCarrierList%2CitineraryDepartureTimeRanges%2CitineraryArrivalTimeRanges%2CdurationSliderItinerary%2CitineraryOrigins%2CitineraryDestinations%2CitineraryStopCountList%2CwarningsItinerary&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22'+self.origin+'%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22' + self.dest + '%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22date%22%3A%22' + leave + '%22%7D%2C%7B%22destinations%22%3A%5B%22'+self.origin+'%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22' + self.dest + '%22%5D%2C%22originPreferCity%22%3Afalse%2C%22date%22%3A%22' + ret + '%22%7D%5D%2C%22startDate%22%3A%22' + self.start_date + '%22%2C%22layover%22%3A%7B%22max%22%3A'+self.max_length+'%2C%22min%22%3A'+self.min_length+'%7D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22' + self.end_date + '%22%2C%22page%22%3A%7B%22size%22%3A30%7D%2C%22sorts%22%3A%22pricePerMile%22%7D'
        print 'get_trips', payload
        page = requests.post(ITADao.url, data=payload, headers=ITADao.headers)
        text = page.text[4:]
        print text
        data = json.loads(text)
        try:
            flights = data['result']['solutionList']['solutions']
            return flights
        except KeyError:
            print "Error. Couldn't get trip info"
            return []


