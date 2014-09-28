__author__ = 'Brad'

from flask import Flask
import datetime
from ITADao import ITADao

"""
API:
best value
lowest price
lowest priced best value
best valued lowest price
below price
below value
"""

app = Flask(__name__)

@app.route('/best_value/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_best_value(origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_best_value()
    tlist = trips.get_trips()

@app.route('/lowest_price/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_lowest_price(origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_cheapest_trips()
    tlist = trips.get_trips()

@app.route('/below_price/<price>/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_lowest_price(price, origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_trips_below_price(price)
    tlist = trips.get_trips()

@app.route('/below_value/<ppm>/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_lowest_price(ppm, origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_trips_below_ppm(ppm)
    tlist = trips.get_trips()

@app.route('/best_value_then_lowest_price/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_lowest_price(origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_best_value()
    trips = trips.find_cheapest_trips()
    tlist = trips.get_trips()

@app.route('/lowest_price_then_best_value/<origin>/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_lowest_price(origin, dest, start_date, end_date, min_length, max_length):
    trips = get_trips(origin, dest, start_date, end_date, min_length, max_length)
    trips = trips.find_cheapest_trips()
    trips = trips.find_best_value()
    tlist = trips.get_trips()

def get_trips(origin, dest, start_date, end_date, min_length, max_length):
    start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d")
    end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d")
    dao = ITADao(origin, dest, start_date, end_date, min_length, max_length)
    return dao.get_trip_data()

if __name__ == '__main__':
    app.run(debug = True)