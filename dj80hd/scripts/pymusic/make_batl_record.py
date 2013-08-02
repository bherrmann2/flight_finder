#!/usr/bin/env python

import wave # 1
import struct
import random

import sys, os, re
import glob
from optparse import OptionParser
FRAME_RATE = 44100  
SECONDS_PER_REV = float(1.8)
SECONDS_PER_EIGTH= float(1.8) / 8
FRAMES_PER_REV = FRAME_RATE * SECONDS_PER_REV
FRAMES_PER_8TH = FRAMES_PER_REV / 8
FRAMES_PER_4TH = FRAMES_PER_REV / 4
SECS_PER_4TH = SECONDS_PER_REV / 4
DELAY_FRAMES = 0

def logit(s):
    print ">>>" + s

def get_rev(frame_number):
    return frame_number/FRAMES_PER_REV
   

def get_silence_data(nframes):
    data = ""
    for i in range(int(nframes)):
        data = data + struct.pack("<hh", 0,0)
    return data

#Get wav data for a given file normalized to stereo, 44100 
def get_wav_data(file_name):
    ifile = wave.open(file_name)
    (nchannels, sampwidth, framerate, nframes, comptype, compname) = ifile.getparams()
    fmts = (None, "=B", "<hh", None, "=l")
    fmt = fmts[sampwidth]

    #print "fmt is " + fmt
    dcs  = (None, 128, 0, None, 0)
    dc = dcs[sampwidth]
    frame_count = ifile.getnframes()
    secs = float(frame_count)/framerate
    #print "Got " + str(frame_count) + " frames, " + str(secs) + " secs."
    data = ""
    for i in range(frame_count):
        iframe = ifile.readframes(1)
        (left,right) = struct.unpack(fmt, iframe)
        #left = 0  
        data = data + struct.pack(fmt, left,right)
    ifile.close()
    return (data,secs,nframes)

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
    raise "NOT IMPLEMENTED YET"

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
#FIXME - Make this required
parser.add_option("-o", "--out", dest="o",
                  help="output wav file", metavar="FILE")

(options, args) = parser.parse_args()
output_filename = 'output.wav'
if options.o:
    output_filename = options.o
    
if options.f:
    file_list = get_file_list(options.f)
    print "GOT FILES " + str(file_list)
else:
    error_exit("File was not specified.\n" + USAGE)


logit("4th is %s secs. %s frames" % (str(SECS_PER_4TH),str(FRAMES_PER_4TH)))




output_file = wave.open(output_filename,"w")
output_file.setnchannels(2)
output_file.setsampwidth(2)
output_file.setframerate(FRAME_RATE)
frames_written = 0

for f in file_list:
    logit("Getting data for file " + f)
    (data,secs,nframes) = get_wav_data(f)
    start_rev = get_rev(frames_written)
    end_rev = get_rev(frames_written+nframes)
    logit("Writing %s secs (%s frames) of audio srev %s erev %s" % (secs,nframes,start_rev,end_rev))
    
    output_file.writeframes(data)
    frames_written += nframes
    
    
    frames_of_silence = FRAMES_PER_4TH - (nframes % FRAMES_PER_4TH)
    data = get_silence_data(frames_of_silence)
    frames_written += frames_of_silence
    seconds_of_silence = float(frames_of_silence) / FRAME_RATE
    logit("Writing %s secs (%s frames) of silence" % (seconds_of_silence,frames_of_silence))

output_file.close()






