__author__ = 'Nick Ruiz'

class FlightRequest(object):
    """
    Contains search parameters for a single flight
    """
    def __init__(self, origins, destinations, depart_date, date_minus=0, date_plus=0, route_language=None, command_line=None):
        self.origins = [origin.strip() for origin in origins.strip().split(',')]
        self.destinations = [dest.strip() for dest in destinations.strip().split(',')]
        self.depart_date = depart_date # TODO: Make sure this is a date.
        self.date_minus = int(date_minus)
        self.date_plus = int(date_plus)
        self.route_language = route_language
        self.command_line = command_line 
        
    def to_json(self):
        req = dict()
        req['origins'] = self.origins
        req['originPrefercity'] = False
        req['destinations'] = self.destinations
        req['date'] = self.depart_date
        req['isArrivalDate'] = False
        req['dateModifier'] = { 'minus' : self.date_minus, 'plus' : self.date_plus}
        if self.route_language:
            req['routeLanguage'] = self.route_language
        if self.command_line:
            req['commandLine'] = self.command_line
            
        return req

class FlightRequestCollection(object):
    '''
    Collects all flights in a trip request
    '''    
    def __init__(self, flights=None, cabin='COACH', currency=None, sales_city=None, max_stops=None, \
                 num_adults=1, num_children=0, num_seniors=0, num_infants_seat=0, num_infants_lap=0, num_youth=0, sort_type='default'):
        '''
        Constructor
        '''
        self.cabin = cabin
        self.currency = currency
        self.sales_city = sales_city
        self.max_stops = max_stops
        
        self.num_adults = num_adults
        self.num_children = num_children
        self.num_seniors = num_seniors
        self.num_infants_seat = num_infants_seat
        self.num_infants_lap = num_infants_lap
        self.num_youth = num_youth
        self.sort_type = sort_type
        
        if flights is not None:
            self.flights = flights
        else:
            self.flights = []
    
    def add_flight(self, flight_request):
        self.flights.append(flight_request)
        
    def add_single_flight(self, origins, destinations, depart_date, date_minus=0, date_plus=0, route_language=None, command_line=None):
        self.add_flight(FlightRequest(origins, destinations, depart_date, date_minus, date_plus, route_language, command_line))
            
    def add_return_flight(self, origins, destinations, depart_date, return_date, date_minus=0, date_plus=0, route_language=None, command_line=None):
        """
        Adds two single flights, corresponding to a round-trip flight.
        TODO: route_language and command_line are passed blindly into the return trip. This could lead to bugs.
        """
        self.add_single_flight(origins, destinations, depart_date, date_minus, date_plus, route_language, command_line)
        self.add_single_flight(destinations, origins, return_date, date_minus, date_plus, route_language, command_line) # TODO: FIX route_language, command_line
        
    def to_json(self):
        req = dict()
        req['slices'] = [f.to_json() for f in self.flights]
        
        # Passengers
        pax = dict()
        if self.num_adults > 0:
            pax['adults'] = self.num_adults
        if self.num_children > 0:
            pax['children'] = self.num_children
        if self.num_seniors > 0:
            pax['seniors'] = self.num_seniors
        if self.num_infants_seat > 0:
            pax['infantsInSeat'] = self.num_infants_seat
        if self.num_infants_lap > 0:
            pax['infantsInLap'] = self.num_infants_lap
        if self.num_youth > 0:
            pax['youth'] = self.num_youth
        req['pax'] = pax
        
        if self.cabin:
            req['cabin'] = self.cabin
        if self.sales_city:
            req['salesCity'] = self.sales_city
        if self.currency:
            req['currency'] = self.currency.upper()
        if self.max_stops:
            req['maxStopCount'] = self.max_stops
            
        req['changeOfAirport'] = True
        req['checkAvailability'] = True
        req['page'] = { 'size' : 30 } # TODO: Change paging
        req['sorts'] = self.sort_type # Also handles pricePerMile
        
        return req
        
        