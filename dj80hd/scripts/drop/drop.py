
import os, stat, mimetypes, httplib,urlparse,urllib,sys,re
from crippter import Crippter
from urlparse import urlparse

DEBUG = True

#TODO
# - Filenames can't have spaces
# - Support proxies ?
# -

DROPURL = "http://127.0.0.1/mine/drop.php"



def post_multipart(url, fields, files):
    """
    Post fields and files to an http host as multipart/form-data.
    @param url: url to post data (e.g. http://foo.com/cgi-bin/pic_upload.php)
    @param fields: a sequence of (name, value) elements for regular form fields.  For example:
        [("vals", "16,18,19"), ("foo", "bar")]
    @param files: a sequence of (name, file) elements for data to be uploaded as files.  For example:
    [ ("mugshot", open("/images/me.jpg", "rb")) ]
    @return: the server's response page.
    """

    host,selector = url_split(url)


    #If proxy stuff is needed.
    #conn = httplib.HTTPConnection(proxyHost, proxyPort)
    #conn.request("POST", "http://www.google.com", params)

    content_type, body = _encode_multipart_formdata(fields, files)
    c = httplib.HTTPConnection(host)
    headers = {
        'User-Agent': 'python_multipart_caller',
        'Content-Type': content_type
    }
    c.request('POST', selector, body, headers)
    res = c.getresponse()
    return res.read()

def _encode_multipart_formdata(fields, files):
    """
@return: (content_type, body) ready for httplib.HTTP instance
    """

    BOUNDARY = '----------ThIs_Is_tHe_bouNdaRY_$'
    CRLF = '\r\n'
    L = []
    for (key, value) in fields:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"' % key)
        L.append('')
        L.append(value)
    for (key, fd) in files:
        file_size = os.fstat(fd.fileno())[stat.ST_SIZE]
        filename = fd.name.split('/')[-1]
        contenttype = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
        L.append('--%s' % BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
        L.append('Content-Type: %s' % contenttype)
        fd.seek(0)
        L.append('\r\n' + fd.read())
    L.append('--' + BOUNDARY + '--')
    L.append('')
    body = CRLF.join(L)
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def error_exit(msg):
    """
    Exit the program with error message"""
    print "ERROR: " + msg
    exit(1)

def logit(s):
    if DEBUG:
        print ">>>" + s

def drop_download(code,passwd):
    """

    Takes a code (e.g. 772847) and a password
    Gets the file from the server, decripts it
    and returns the filename in which it is stored.
    """
    #File comes down as .drop and text plain.
    c = Crippter(passwd)

    host,selector = url_split(DROPURL)
    path = selector + "?action=drop_download&code=" + code

    conn = httplib.HTTPConnection(host)
    logit("requesting " + path + " at host " + host)
    conn.request("GET", path)
    r = conn.getresponse()
    content = r.read()

    ct = r.getheader('Content-Type')
    if (ct != 'text/plain'):
        error_exit("Content type is unexpected: " + ct)

    if (' ' in content):
        error_exit("Response Content cannot have whitespace: " + content)
    logit("GOT CONTENT:" + content)
    content = content.strip()

    logit("GOT STRIPPED CONTENT:" + content)

    if r.status != 200:
        error_exit("Got HTTP Error " + str(r.status) + " " + r.reason + "\nContent:" + content)

    conn.close()



    cd = r.getheader('Content-Disposition')
    if cd:
        s = re.search('filename="(.*)"', cd, re.IGNORECASE)
        if s:
            filename = s.group(1)
            logit("Will save content in file " + filename)
            c.decryptStringToFile(content,filename)
            logit("Done.")
            return filename
        else:
            #e.g.
            error_exit("No filename in Content-Disposition Header in here: " + cd + "\nContent:" + content)

    else:
        error_exit("There was no Content-Disposition in here: " + str(r.getheaders()) + "\nContent:" + content)








def drop_upload(filename,passwd):
    """Guaranteed to return a string that is a digit"""
    c = Crippter(passwd)
    filename2 = filename + ".drop"
    logit("encrypting " + filename + " to " + filename2 + " with psswd " + passwd)
    c.encryptFile(filename,filename2)
    logit("Done.  Now uploading...")
    params = [("action","drop_upload"),("secret","kerry4"),("filename",filename2)]
    files = [("drop",open(filename2,"rb"))]
    resp_content = post_multipart(DROPURL,params,files)
    if resp_content.strip().isdigit():
        return resp_content.strip()
    else:
        #FIXME good exception type.
        raise Exception("THis is not a good response: " + resp_content)

def url_split(url):
    parsed_url = urlparse(url)
    return parsed_url.netloc, parsed_url.path






USAGE="""USAGE:

Step 1: Upload the file (a code will be returned)

  python drop.py <filename> <password>

Step 2: Download the file on another machine

  python drop.py <code> <password>


Example:

1. On one machine upload the file
  python drop.py rpms/myjank.rpm mysecretword

2. The output will provide a numeric code and look something like this:

  Success!  Run this command to retrieve your file:
  python drop.py 234281 mysecretword

3. On another machine just simply follow the instructions:

   python drop.py 234281 myscretword"""

if len(sys.argv) < 3:
    print USAGE
    sys.exit(0)


first_arg = sys.argv[1]
passwd = sys.argv[2]

if first_arg.isdigit():
    code = first_arg
    drop_download(code,passwd)

elif os.path.isfile(first_arg):
    filename = first_arg
    code = drop_upload(filename,passwd)
    print "Success! Run this command to retrieve your flie:\npython drop.py %s %s\n" % (code, passwd)

else:
    print "It appears this is neither a code or a valid file name: " + first_arg
    exit


