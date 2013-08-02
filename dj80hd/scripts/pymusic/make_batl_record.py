#!/usr/bin/env python

import wave # 1
import struct
import random

import sys, os, re
import glob
from optparse import OptionParser

def get_file_list(f):
    #FIXME - raise instead of error_exit ?
    file_list = None
    if os.path.exists(f):
        if os.path.isdir(f):
            file_list = glob.glob(f + "/*.wav")
        else: #is a file
            if f.endswith(".m3u"):
                process_m3u(f)
            else:
                error_exit("The following does not appear to be an .m3u file: " + f)
    else:
        error_exit("The following path/file does not exist: " + f)

    return file_list        


def process_m3u(m3u):
    pass
def error_exit(msg):
    print "ERROR: " + msg
    sys.exit(666)


input_file = "808kick.wav"

fmts = ".wav"

USAGE = """
USAGE:
python %s -f <list_of_files>

<list_of_files> can be one of the following:
- a directory
  all %s files in the directory will be placed
  in the batl record in alpha order

""" % (sys.argv[0],fmts)



parser = OptionParser()
parser.add_option("-f", "--file", dest="f",
                  help="file list", metavar="FILE")

(options, args) = parser.parse_args()

if options.f:
    file_list = get_file_list(options.f)
    print "GOT FILES " + str(file_list)
else:
    error_exit("File was not specified")
    
SECONDS_PER_REV = float(1.8)
DELAY_SECONDS = float(1.8 / 8)
DELAY_FRAMES = 0



    

    






ifile = wave.open(input_file)
ofile = wave.open("output.wav", "w")
ofile.setparams(ifile.getparams())
(nchannels, sampwidth, framerate, nframes, comptype, compname) = ifile.getparams()

channel_count = ifile.getnchannels()
print str(channel_count) + " channels"
sampwidth = ifile.getsampwidth()
print "sampwidth is " + str(sampwidth)
print "framerate is " + str(framerate)
fmts = (None, "=B", "<hh", None, "=l")
fmt = fmts[sampwidth]

print "fmt is " + fmt
dcs  = (None, 128, 0, None, 0)
dc = dcs[sampwidth]
frame_count = ifile.getnframes()
secs = float(frame_count)/framerate
print "Got " + str(frame_count) + " frames, " + str(secs) + " secs."


#Loop to mute the left stereo channel
for i in range(frame_count):
    iframe = ifile.readframes(1)
    (left,right) = struct.unpack(fmt, iframe)
    #left = 0  
    oframe = struct.pack(fmt, left,right)
    ofile.writeframes(oframe)

ifile.close()
ofile.close()