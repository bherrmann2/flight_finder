__author__ = 'brherrma'

from flask import Flask
import datetime
from ITADao import ITADao

app = Flask(__name__)

@app.route('/best_value/<dest>/<start_date>/<end_date>/<min_length>/<max_length>', methods= ['GET'])
def get_best_value(dest, start_date, end_date, min_length, max_length):
    start_date = datetime.datetime.strptime(start_date, "%Y-%m-%d")
    end_date = datetime.datetime.strptime(end_date, "%Y-%m-%d")
    dao = ITADao(dest, start_date, end_date, min_length, max_length)
    trips = dao.get_trip_data()
    trips = trips.find_best_value()
    tlist = trips.get_trips()


if __name__ == '__main__':
    app.run(debug = True)