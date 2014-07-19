__author__ = 'Brad'

from Flight import Flight
from Trip import Trip

class ITATrips():
    def __init__(self, trips = []):
        self.trips = trips

    """
    Adds the trips inside the json data returned by an ITA trip request.
    This should only be called if the caller understands the json returned by ITA,
    thus it is "protected" to the ITA package
    """
    def _add_trips(self, trips):
        for trip in trips:
            self.trips.append(self.__get_trip(trip))

    """
    finds all the trips below a specified ppm
    returns an ITATrips object of only those trips
    """
    def find_trips_below_ppm(self, ppm):
        trips = []
        for trip in self.trips:
            if trip.ppm <= ppm:
                trips.append(trip)

        return ITATrips(trips)

    """
    finds all the trips below a specified price
    returns an ITATrips object of only those trips
    """
    def find_trips_below_price(self, max_price):
        trips = []
        for trip in self.trips:
            if trip.price <= max_price:
                trips.append(trip)

        return ITATrips(trips)

    """
    finds all the trips equal to the lowest price
    returns an ITATrips object of only those trips
    """
    def find_cheapest_trips(self):
        #sort the list by price
        trips = sorted(self.trips, key=lambda trip: trip.price)

        cheapest = []
        lowest = trips[0]
        for trip in trips:
            #find all trips that equal the cheapest
            if trip.price == lowest.price:
                cheapest.append(trip)
            else:
                break;

        return ITATrips(cheapest)


    """
    find all the trips that equal the lowest ppm
    returns an ITATrips object of only those trips
    """
    def find_best_value(self):
        #sort the list by ppm
        trips = sorted(self.trips, key=lambda trip: trip.ppm)

        best = []
        lowest = trips[0]
        for trip in trips:
            #find all trips that equal the lowest ppm
            if trip.ppm == lowest.ppm:
                best.append(trip)
            else:
                break;

        return ITATrips(best)

    """
    returns a list of all the trips
    """
    def get_trips(self):
        return self.trips


    def __get_trip(self, trip):
        price = float(trip['ext']['price'][3:])
        tppm = float(trip['ext']['pricePerMile'][3:])
        tppm = round(tppm, 4)
        itin = trip['itinerary']
        distance = int(itin['distance']['value'])

        flights = []
        for flight in itin['slices']:
            stops = []
            layovers = flight.get('stops')
            if not layovers is None:
                for layover in layovers:
                    stops.append(layover['code'])

            fl = Flight(flight['origin']['code'], flight['destination']['code'],flight['departure'], flight['arrival'], flight['duration'], stops)
            flights.append(fl)

        return Trip(flights[0], flights[1], tppm, price, distance)
