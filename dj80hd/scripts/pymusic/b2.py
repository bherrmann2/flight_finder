import wave, struct, math

w = wave.open("input.wav",'r')
y = wave.open("output.wav","w")
t = """
Number of Channels: %s
Width: %s
Frequency: %s
Number of Frames: %s
Compression Type: %s
Readable: %s
Params: %s
Rewind: %s
Markers: %s
Tell: %s
Position(4): %s
"""%(w.getnchannels(),w.getsampwidth(),w.getframerate(),w.getnframes(),w.getcomptype(),w.getcompname(),w.getparams(),w.rewind(),w.getmarkers(),w.tell(),w.setpos(4))

print t

kanallar = w.getparams()[0]
sampwidth= w.getparams()[1]
frekans = 25
kareler = w.getparams()[3]
comtype = w.getparams()[4]
comname = w.getparams()[5]

yeniparams = (kanallar,sampwidth,frekans,kareler,comtype,comname)

t1 = "Eski parametler: %s\nYeni parametreler: %s"%(w.getparams(),yeniparams)

print t1

y.setparams(yeniparams)

sw= w.getsampwidth()
fmts = (None,"=B","hhl",None,"=l")
fmts = (None,"=B","=h",None,"=l")
fmt = fmts[sw]
dcs = (None,128,0,None,0)
dc = dcs[sw]
for i in range(w.getnframes()):
  iframe = w.readframes(1)
  iframe = struct.unpack(fmt,iframe)[0]

  oframe = iframe / 2;
  oframe += dc;
  oframe = struct.pack(fmt, oframe)
  y.writeframes(oframe)

w.close()
y.close()

print "Complete!"