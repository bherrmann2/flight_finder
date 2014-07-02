__author__ = 'Brad Herrmann'

class ITACalendar:
    def __init__(self, data):
        self.data = data

    def get_lowest_price(self):
        return self.data["result"]["currencyNotice"]["ext"]["price"]

    def get_session_id(self):
        return self.data["result"]["session"]

    """
    finds the cheapest round trip
    returns a list containing the day leaving and the day returning
    """
    def find_cheapest_rt(self):
        calendar = self.data["result"]["calendar"]
        minPrice = self.get_lowest_price()
        print minPrice
        cheapest_dates = []
        for month in calendar["months"]:
            year = month["year"]
            the_month = month["month"]
            day_num = 1
            for week in month["weeks"]:
                for day in week["days"]:
                    date = day["date"]

                    #exclude dates in the week not in the current month. ie. exclude 6/30 in
                    # Monday 6/30, Tuesday 7/1, Wednesday 7/2, etc since 6/30 is not in July
                    if date != day_num:
                        continue
                    day_num = day_num+1
                    price = day.get("minPrice")
                    if price == minPrice:
                        dates = []
                        dates.append(str(year) + "-" + str(the_month) + "-" + str(date))
                        for trip in day["tripDuration"]["options"]:
                            #for flight in trip["options"]:
                            if minPrice == trip["minPrice"]:
                                arrival = trip["solution"]["itinerary"]["arrival"]
                                arrival = arrival[:10] #strip off the time
                                dates.append(arrival)
                                cheapest_dates.append(dates)
        return cheapest_dates