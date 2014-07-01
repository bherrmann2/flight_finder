__author__ = 'Brad'

from Flight import Flight
from Trip import Trip

class ITATrips():
    def __init__(self, trips):
        self.trips = trips

    def find_trips_below_ppm(self, ppm):
        retVal = []
        for trip in self.trips:
            tppm = float(trip['ext']['pricePerMile'][3:])
            if tppm <= ppm:
                price = float(trip['ext']['price'][3:])
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

                the_trip = Trip(flights[0], flights[1], tppm, price, distance)
                retVal.append(the_trip)
        return retVal