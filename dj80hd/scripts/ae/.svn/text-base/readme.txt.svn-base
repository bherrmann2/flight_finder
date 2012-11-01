= Overview =
Aardvark Extreme (also known as Novarra Online Analytic Replay/NOAR)
will periodically load and display urls form logs in near-real time AS THE END USER sees them.
It will also show how these URLs appear on a real desktop browser, giving feedback on how Novarra's
Content Adaptation is actually working

= Glossary =
* AE - Acronym for 'Aardvark Extreme' / 'Aardvark Extreme GUI'; The client/user visible destop application
       that displays to viewers what real customers are actually browsing.
* AEBS - Acronym for 'Aardvark Extreme Backend Server'          
* UA - Acronym for User Agent
* load parameter data - Includes a url, UA, and an aca.  Requested from AE
                      and returned by AEBS
* scraper data - a Set of URL/UA combinations sent from the Log Scraper


= Key Components =
== Aardvark Extreme GUI ==
* AE (Aardvark Extreme) is the user-visible application that will occupy large
  flat panel monitors.
* AE periodically requests information from the Backend Server.
* This inforamtion includes what URLs to load with what user agents on what aca
  This information is know as 'load request parameters'
* AE shows the results of loading the URL through an aca as well as loading
  the URL directly.

== Aardvark Extreme Backend Server (AEBS) ==
The Backend Server (AEBS) does the following:
# Receives scraper data from the Log Scraper.  
# Handles requests from the AE GUI for load request parameters.
# Provides a Mobile Inteface for Mobile Clients 
# Provides a Web Interface for Web Clients.

== Log Scraper ==
The Log Scraper periodically scrapes production logs and sends the data to the
Backend Server.

== Web UI ==
The Web UI:
# Is hosted on the AEBS
# Administration of the backend server.
# A monitor applicaiton where one can see what URLS are being sent 
  and what they look like loaded through the Novarra Server.
# 
== Mobile UI ==
The Mobile UI is
# Hosted on the AEBS
# Provides a url dialog box to load a url.  This url is loaded through the aca AND
  then put first in the queue to be sent to AE.  That way, when a user loads a
  url through this interface, it shows up in near-real time on the AE GUI.


= FAQ =
== What format are the load request parameter sent from the AEBS ? ==
== What format is the scaper data sent ? ==
== What are the details of the Client/Server interface ? ==
=== Getting more URL/UAs to load ===
==== Request ====
     FORMAT: ?action=get_next&type=<type>&cust=<cust>&count=count
     where <type> is aardvark or j2me or brew 
     and   <cust> is vfuk | eetg | 3hk | 3it | uscc | turkcell etc.
           (Note, cust can also be 'any' to select from any customer)
     EXAMPLE:
       ?action=get_next&type=aardvark&count=4

== What are the details of the Scraper/Server interface ? ==
     Adding url/ua data to the system.
     FORMAT: HTTP post with the following parameters...
     code = (3it | 3hk | vfuk | turkcell ... etc.)
     action = add_data
     data = A newline seperated lists of url-ua pairs where the url-ua
            is seperated by a | (See B. Example data section)

     Example:         
       ...
       http://mycounter.tinycounter.com|BlackBerry7130e/4.1.0
       http://88.214.227.83|Nokia6133/2.0 (05.60) Profile/MIDP-2.0 CLDC-1.1
       ...

== What are the details of the mobile voyeur interface ? ==
   
== What are all the files in the software package and their purpose ? ==
  # aardvark_extreme.php is the Backend Server
  # aescraper.pl is the Log Scraper.
  # config.yml is the config file for the Backend Server
  # simple_html_dom.php, simple_html_dom_utility.php, URL.php, and spyc.php
    are all libraries used by the Backend server.
  # m.htm is the mobile interface to the backend server.
  # ie_monitor.html is the web mointor page where you can see what is being
    sent.


== What are all the error codes that can be returned from the Backend Server ?==
This application has its own set of HTTP error codes 6xx as follows:

   601 - Invalid data format to be added.
   602 - Invalid IP (IP is not allowed to access The system)
   605 - System could not find a random canned entry
