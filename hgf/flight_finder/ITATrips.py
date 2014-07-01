__author__ = 'Brad'



class ITATrips():
    def __init__(self, trips):
        self.trips = trips

    def find_trips_below_ppm(self, ppm):
        for trip in self.trips:
            tppm = float(trip['ext']['pricePerMile'][3:])
            if tppm <= ppm:
                price = int(trip['ext']['price'][3:0])
                itin = trip['itinerary']
                distance = int(itin['distance']['value'])
                outbound_data = itin['slices'][0]
                inbound_data = itin['slices'][1]

                outbound = ITAF