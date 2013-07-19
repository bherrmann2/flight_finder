#!/usr/bin/env python

import wave # 1
import struct

ifile = wave.open("input.wav")
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
print "Got " + str(frame_count) + " frames"

for i in range(frame_count):
    iframe = ifile.readframes(1)
    print "iframe is " + str(len(iframe)) + " bytes"

    iframes = struct.unpack(fmt, iframe)
    print "iframes is now " + str(iframes)
    iframe = iframes[0]
    print "iframe is now " + str(iframe)
    iframe -= dc

    oframe = iframe / 2;

    oframe += dc
    oframe = struct.pack(fmt, oframe)
    ofile.writeframes(oframe)

ifile.close()
ofile.close()