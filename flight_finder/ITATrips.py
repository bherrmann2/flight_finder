__author__ = 'Brad'

from Flight import Flight
from Trip import Trip


class ITATrips():
    """
    Handles the trip data returned from ITA
    """
    def __init__(self, trips = None):
        if trips is None:
            trips = []
        self.trips = trips


    def _add_trips(self, trips):
        """
        Adds the trips inside the json data returned by an ITA trip request.
        This should only be called if the caller understands the json returned by ITA,
        thus it is "protected" to the ITA package
        """
        for trip in trips:
            self.trips.append(self.__get_trip(trip))


    def find_trips_below_ppm(self, ppm):
        """
        finds all the trips below a specified ppm
        returns an ITATrips object of only those trips
        """
        trips = []
        for trip in self.trips:
            if trip.ppm <= ppm:
                trips.append(trip)

        return ITATrips(trips)


    def find_trips_below_price(self, max_price):
        """
        finds all the trips below a specified price
        returns an ITATrips object of only those trips
        """
        trips = []
        for trip in self.trips:
            if trip.price <= max_price:
                trips.append(trip)

        return ITATrips(trips)


    def find_cheapest_trips(self):
        """
        finds all the trips equal to the lowest price
        returns an ITATrips object of only those trips
        """

        #sort the list by price
        trips = sorted(self.trips, key=lambda trip: trip.price)

        cheapest = []
        if len(trips) == 0:
            return ITATrips(cheapest)
        lowest = trips[0]
        for trip in trips:
            #find all trips that equal the cheapest
            if trip.price == lowest.price:
                cheapest.append(trip)
            else:
                break

        return ITATrips(cheapest)



    def find_best_value(self):
        """
        find all the trips that equal the lowest ppm
        returns an ITATrips object of only those trips
        """

        #sort the list by ppm
        trips = sorted(self.trips, key=lambda trip: trip.ppm)

        best = []
        lowest = trips[0]
        for trip in trips:
            #find all trips that equal the lowest ppm
            if trip.ppm == lowest.ppm:
                best.append(trip)
            else:
                break

        return ITATrips(best)


    def get_trips(self):
        """
        returns a list of all the trips
        """
        return self.trips

    def __get_trip(self, trip):
        """
        Gets the trip information out of the json returned from ITA
        This should only be called if the caller understands the json returned by ITA
        """
        price = float(trip['ext']['price'][3:])
        ppm = float(trip['ext']['pricePerMile'][3:])
        ppm = round(ppm, 4)
        itin = trip['itinerary']
        distance = int(itin['distance']['value'])

        flights = []
        #get the flights out of the itinerary
        for flight in itin['slices']:
            stops = []
            layovers = flight.get('stops')
            if not layovers is None:
                for layover in layovers:
                    stops.append(layover['code'])

            fl = Flight(flight['origin']['code'], flight['destination']['code'],flight['departure'], flight['arrival'], flight['duration'], stops)
            flights.append(fl)

        return Trip(flights[0], flights[1], ppm, price, distance)
