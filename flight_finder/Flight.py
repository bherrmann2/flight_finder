__author__ = 'Brad'

class Flight():
    """
    Stores the flight information such as origin, destination, departure and arrival times, duration, and stops
    """
    def __init__(self, origin, dest, depart, arrive, duration, stops):
        self.origin = origin
        self.dest = dest
        self.depart = depart
        self.arrive = arrive
        self.duration = duration
        self.stops = stops
