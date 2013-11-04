from ID3 import *
from mutagen import *
from mutagen.mp3 import MP3
from mutagen.easyid3 import EasyID3
def main():
    try:
        id3info = ID3('mt_goon.mp3')
        print id3info
        id3info['TITLE'] = "Green Eggs and Ham"
        print "--------------\n"
        for k, v in id3info.items():
            print k, "-:-", str(v), "\n"
        my_mp3 = MP3('mt_goon.mp3')
        audio = MP3("mt_goon.mp3", ID3=EasyID3)
        print ">>>\n"
        print EasyID3.valid_keys.keys()
        print audio['title'][0]
        print ">>>\n"
    except InvalidTagError, message:
        print "Invalid ID3 tag:", message

main()