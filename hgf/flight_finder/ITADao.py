__author__ = 'Brad Herrmann'

import json
import requests
from ITACalendar import ITACalendar
from ITAFlights import ITAFlights
from ITATrips import ITATrips


class ITADao:

    flight_cookie = '__utma=269716137.1963755597.1368591497.1368846168.1369958808.3; __utma=241137183.308417330.1368591501.1403974868.1403991047.140; __utmz=241137183.1402970608.133.6.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); searchFormState=%7B%22version%22%3A%220.7.20120825.1%22%2C%22json%22%3A%22%7B%5C%22mode%5C%22%3A%7B%5C%22date%5C%22%3A%5C%22calendar%5C%22%2C%5C%22flightSelection%5C%22%3A%5C%22slice%5C%22%2C%5C%22flightView%5C%22%3A%5C%22slice%5C%22%2C%5C%22pageFlow%5C%22%3A%5C%22calendar%5C%22%2C%5C%22trip%5C%22%3A%5C%22rt%5C%22%2C%5C%22calendarRange%5C%22%3A%5C%2230day%5C%22%7D%2C%5C%22searchForm%5C%22%3A%7B%5C%22mode%5C%22%3A%5C%22advanced%5C%22%2C%5C%22defaults%5C%22%3A%7B%5C%22multiCityRows%5C%22%3A2%7D%2C%5C%22awards%5C%22%3A%5C%22noawards%5C%22%2C%5C%22options%5C%22%3A%7B%5C%22showRoutingCodes%5C%22%3Atrue%2C%5C%22pax%5C%22%3A%5C%22simple%5C%22%7D%7D%7D%22%7D; pricePerMile=%7B%22showControl%22%3Atrue%2C%22showPrice%22%3Atrue%7D; mode.flight=%7B%22view%22%3A%22slice%22%2C%22selection%22%3A%22slice%22%7D; PREF="ID=ddab770e84ffbd166c060d8402d1da5ced52210c7cc1eebfec1ba7ab84841a404416a0bfbf08cb7facfb49969cb56fbd912fb4fc80412f15b2456abb34a0e50f:TM=1403972269:S=052ph5Y8jci3Qu3t"; __utmc=241137183; __utmb=241137183.11.10.1403991047'
    trip_cookie = '__utma=269716137.1963755597.1368591497.1368846168.1369958808.3; __utma=241137183.308417330.1368591501.1403974868.1403991047.140; __utmz=241137183.1402970608.133.6.utmcsr=google|utmccn=(organic)|utmcmd=organic|utmctr=(not%20provided); searchFormState=%7B%22version%22%3A%220.7.20120825.1%22%2C%22json%22%3A%22%7B%5C%22mode%5C%22%3A%7B%5C%22date%5C%22%3A%5C%22calendar%5C%22%2C%5C%22flightSelection%5C%22%3A%5C%22slice%5C%22%2C%5C%22flightView%5C%22%3A%5C%22slice%5C%22%2C%5C%22pageFlow%5C%22%3A%5C%22calendar%5C%22%2C%5C%22trip%5C%22%3A%5C%22rt%5C%22%2C%5C%22calendarRange%5C%22%3A%5C%2230day%5C%22%7D%2C%5C%22searchForm%5C%22%3A%7B%5C%22mode%5C%22%3A%5C%22advanced%5C%22%2C%5C%22defaults%5C%22%3A%7B%5C%22multiCityRows%5C%22%3A2%7D%2C%5C%22awards%5C%22%3A%5C%22noawards%5C%22%2C%5C%22options%5C%22%3A%7B%5C%22showRoutingCodes%5C%22%3Atrue%2C%5C%22pax%5C%22%3A%5C%22simple%5C%22%7D%7D%7D%22%7D; pricePerMile=%7B%22showControl%22%3Atrue%2C%22showPrice%22%3Atrue%7D; mode.flight=%7B%22view%22%3A%22trip%22%2C%22selection%22%3A%22trip%22%7D; PREF="ID=ddab770e84ffbd166c060d8402d1da5ced52210c7cc1eebfec1ba7ab84841a404416a0bfbf08cb7facfb49969cb56fbd912fb4fc80412f15b2456abb34a0e50f:TM=1403972269:S=052ph5Y8jci3Qu3t"; __utmc=241137183; __utmb=241137183.11.10.1403991047'


    headers = \
    {
        "Content-Type" : "application/x-www-form-urlencoded; charset=UTF-8",
        "Cookie" : trip_cookie
    }

    def __init__(self, dest, start, end):
        self.dest = dest
        self.start = start
        self.end = end

    def get_calendar_data(self):
        payload = "name=calendar&summarizers=currencyNotice%2CovernightFlightsCalendar%2CitineraryStopCountList%2CitineraryCarrierList%2Ccalendar&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22ORD%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22"+self.dest+"%22%5D%2C%22destinationPreferCity%22%3Afalse%7D%2C%7B%22destinations%22%3A%5B%22ORD%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22"+self.dest+"%22%5D%2C%22originPreferCity%22%3Afalse%7D%5D%2C%22startDate%22%3A%22"+self.start+"%22%2C%22layover%22%3A%7B%22max%22%3A6%2C%22min%22%3A3%7D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22"+self.end+"%22%7D"
        page = requests.post("http://matrix.itasoftware.com/xhr/shop/search", data=payload, headers=ITADao.headers)
        text = page.text[4:]
        print text
        data = json.loads(text)
        return ITACalendar(data)


    """
    Gets the flights for the particular dates
    """
    def get_flights(self, leave, ret, session):
        payload = 'name=calendarFollowupSlice&session=' + session +'&summarizers=sliceSelections%2CcarrierStopMatrixSlice%2CcurrencyNotice%2CsolutionListSlice%2CpriceSliderSlice%2CcarrierListSlice%2CdepartureTimeRangesSlice%2CarrivalTimeRangesSlice%2CdurationSliderSlice%2CoriginsSlice%2CdestinationsSlice%2CstopCountListSlice%2CwarningsSlice&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22ORD%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22'+self.dest+'%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22date%22%3A%22' + leave + '%22%7D%2C%7B%22destinations%22%3A%5B%22ORD%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22'+self.dest+'%22%5D%2C%22originPreferCity%22%3Afalse%2C%22date%22%3A%22' + ret + '%22%7D%5D%2C%22startDate%22%3A%22' + self.start + '%22%2C%22layover%22%3A%7B%22max%22%3A6%2C%22min%22%3A3%6D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22' + self.end + '%22%2C%22sliceIndex%22%3A0%2C%22page%22%3A%7B%22size%22%3A30%7D%2C%22sorts%22%3A%22default%22%7D'
        page = requests.post("http://matrix.itasoftware.com/xhr/shop/search", data=payload, headers=ITADao.headers)
        text = page.text[4:]
        print text
        data = json.loads(text)
        flights = data['result']['solutionListSlice'][0]['solutions']
        return ITAFlights(flights)


    """
    Gets the RT flights for the particular dates
    """
    def get_trips(self, leave, ret, session):
        #need to get the trip length from the calendar and put in max and min
        payload = 'name=calendarFollowup&session=' + session + '&summarizers=carrierStopMatrix%2CcurrencyNotice%2CsolutionList%2CitineraryPriceSlider%2CitineraryCarrierList%2CitineraryDepartureTimeRanges%2CitineraryArrivalTimeRanges%2CdurationSliderItinerary%2CitineraryOrigins%2CitineraryDestinations%2CitineraryStopCountList%2CwarningsItinerary&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22ORD%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22' + self.dest + '%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22date%22%3A%22' + leave + '%22%7D%2C%7B%22destinations%22%3A%5B%22ORD%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22' + self.dest + '%22%5D%2C%22originPreferCity%22%3Afalse%2C%22date%22%3A%22' + ret + '%22%7D%5D%2C%22startDate%22%3A%22' + self.start + '%22%2C%22layover%22%3A%7B%22max%22%3A3%2C%22min%22%3A3%7D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22' + self.end + '%22%2C%22page%22%3A%7B%22size%22%3A30%7D%2C%22sorts%22%3A%22default%22%7D'
        print payload
        #payload = 'name=calendarFollowupSlice&session=' + session +'&summarizers=sliceSelections%2CcarrierStopMatrixSlice%2CcurrencyNotice%2CsolutionListSlice%2CpriceSliderSlice%2CcarrierListSlice%2CdepartureTimeRangesSlice%2CarrivalTimeRangesSlice%2CdurationSliderSlice%2CoriginsSlice%2CdestinationsSlice%2CstopCountListSlice%2CwarningsSlice&format=JSON&inputs=%7B%22slices%22%3A%5B%7B%22origins%22%3A%5B%22ORD%22%5D%2C%22originPreferCity%22%3Afalse%2C%22destinations%22%3A%5B%22'+self.dest+'%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22date%22%3A%22' + leave + '%22%7D%2C%7B%22destinations%22%3A%5B%22ORD%22%5D%2C%22destinationPreferCity%22%3Afalse%2C%22origins%22%3A%5B%22'+self.dest+'%22%5D%2C%22originPreferCity%22%3Afalse%2C%22date%22%3A%22' + ret + '%22%7D%5D%2C%22startDate%22%3A%22' + self.start + '%22%2C%22layover%22%3A%7B%22max%22%3A6%2C%22min%22%3A3%7D%2C%22pax%22%3A%7B%22adults%22%3A1%7D%2C%22cabin%22%3A%22COACH%22%2C%22changeOfAirport%22%3Afalse%2C%22checkAvailability%22%3Atrue%2C%22firstDayOfWeek%22%3A%22SUNDAY%22%2C%22endDate%22%3A%22' + self.end + '%22%2C%22sliceIndex%22%3A0%2C%22page%22%3A%7B%22size%22%3A30%7D%2C%22sorts%22%3A%22default%22%7D'
        page = requests.post("http://matrix.itasoftware.com/xhr/shop/search", data=payload, headers=ITADao.headers)
        text = page.text[4:]
        print text
        data = json.loads(text)
        flights = data['result']['solutionList']['solutions']
        return ITATrips(flights)