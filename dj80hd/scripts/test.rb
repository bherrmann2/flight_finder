require 'net/http'
require 'uri'

raw = "[NAME:FORWARD TEST email=jim@scissorsoft.com tot=30000 DEVID=1296503647773 CHUNK=1165] [http://mixwidget.org CON=3249 NET=109 HTP=21 IMT=0 IMN=39 IMP=0 PNT=0 TOT=3383 BYT=2842 MEM=827 CHK= null STS=Sat, 05 Mar 2011 07:07:28 GMT CHT=797 AHT=801 CIT=0 AIT=21 DVST=706 THT =1600 TIT=21 UID=666 TTT=1621 NPC=0 PBD=3334 FCT=3304 STST=0 DS=0 IS=1192 SIL=0 SIS=227 PC=1 CHR=0 GZIP=2 IEHL=7 IC=0 ST=0 PST=0 SIT=0 NSI=0 EHS=888 RET=0 TM=2097152]"
int = "1"
sess = "80"
poc = "test.client.palp.com"


data = {'raw_apl_data' => raw, 'interval_minutes' => "5", 'sessionid' => "80", 'point_of_contact' => poc}

url = "http://scissorsoft.com/php/formforward.php"
res = Net::HTTP.post_form(URI.parse(url),data)
puts res.code
puts res.body

