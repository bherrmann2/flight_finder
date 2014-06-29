__author__ = 'Brad'

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