__author__ = 'Brad'

class Trip():
    def __init__(self, outbound, inbound, ppm, price, distance):
        self.ppm = ppm
        self.outbound = outbound
        self.inbound = inbound
        self.price = price
        self.distance = distance

    def to_string(self):
        print "Found a cheap " + self.outbound.origin + "-" + self.outbound.dest + " trip from " + self.outbound.depart + " to " + self.inbound.arrive + " with ppm=" + str(self.ppm) + ", price=" + str(self.price) + ", distance" + str(self.distance)
