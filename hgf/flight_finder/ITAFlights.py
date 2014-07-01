__author__ = 'Brad'

from Trip import Trip

class ITAFlights():
    def __init__(self, flights):
        self.flights = flights

    def find_lowest_ppm(self):
        low_ppm = 999 #nothing will be $999 per mile
        for flight in self.flights:
            ppm = float(flight.get("minPricePerMile")[3:])
            if ppm < low_ppm:
                low_ppm = ppm

        return low_ppm

    def find_flights_below_ppm(self, ppm):
        for flight in self.flights:
            mppm = float(flight.get("minPricePerMile")[3:])
            if mppm <= ppm:
                price = int(flight.get("minPrice")[3:])
                dist = flight['solution']['itinerary']['distance']['value']
