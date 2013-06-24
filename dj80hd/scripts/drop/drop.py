
import os, stat, mimetypes, httplib,urlparse,urllib,sys,re,base64

from urlparse import urlparse

DEBUG = True

#TODO
# - Filenames can't have spaces
# - IDEA: http://stackoverflow.com/questions/5925028/urllib2-post-progress-monitoring
# -

DROPURL = "http://127.0.0.1/mine/drop.php"
DROPURL = "http://scissorsoft.com/php/drop/drop.php"

class Crippter:
    """ Crippter is a class that provides very simple password encryption
    """

    def __init__(self,p):
        """
        @param p - secret password to be used with this Crippter
        """
        self.password = p
        #Secret voodoo
        self.c=""
        for x in range(33,127): self.c+=chr(x)

    def encryptFile(self,fin,fout):
        """
        Encrypt the contents of a file and put it in a new file.
        @param fin filename to be encrypted
        @param fout filename to put the encrpyted contents.
               Will be overwritten if it exists."""

        #Let any exceptions go up to caller
        stringContents = open(fin, 'rb').read()
        encryptedStringContents = self.encryptString(stringContents)
        f = open(fout,'wb')
        f.write(encryptedStringContents)
        f.close()

    def encryptString(self,s):
        """Encrypt a String using magic voodoo and return it.
        @param s string to be encrypted.
        @returns encrypted version guaranteed to be ascii without spaces."""
        k = self.password
        s = base64.b64encode(s)
        s2=[self.c.find(v) for v in s]
        k2=[]
        i=0
        while len(k2) != len(s):
            if i >= len(k):
                i = 0
            k2.append(self.c.find(k[i]))
            i+=1
        r=[self.c[(j+k)%len(self.c)] for j,k in zip(s2,k2)]
        return  "".join(r)

    def decryptFile(self,fin,fout):
        """Decrypt a file and place it in a new file.
        @param fin - file containing encrypted contents.
        @param fout - file to place unencrypted contents."""
        #Let any exceptions go up to caller
        s = open(fin, 'rb').read()
        decryptedStringContents = self.decryptString(s)
        f = open(fout,'wb')
        f.write(decryptedStringContents)
        f.close()

    def decryptString(self,r):
        """ Decrypt a string using magic voodoo
        @param r string to decrypt
        @returns decrypted string"""
        k = self.password
        r2=[self.c.find(v) for v in r]
        k2=[]
        i=0
        while len(k2) != len(r):
            if i >= len(k):
                i = 0
            k2.append(self.c.find(k[i]))
            i+=1
        s=[self.c[(j-k)%len(self.c)] for j,k in zip(r2,k2)]
        return base64.b64decode("".join(s))

    def decryptStringToFile(self,r,filename):
        """Convenience method to decrypt a string and place it in a file.
        @param r string to decrypt
        @param filename file to create with the decrypted contents."""
        r2 = self.decryptString(r)
        f = open(filename,'wb') #wb ok ?
        f.write(r2)
        f.close()

def post_multipart(url, fields, files, proxy):
    """
    Post fields and files to an http host as multipart/form-data.
    @param url: url to post data (e.g. http://foo.com/cgi-bin/pic_upload.php)
    @param fields: a sequence of (name, value) elements for regular form fields.  For example:
        [("vals", "16,18,19"), ("foo", "bar")]
    @param files: a sequence of (name, file) elements for data to be uploaded as files.  For example:
    [ ("mugshot", open("/images/me.jpg", "rb")) ]
    @return: the server's response page.
    """




    #If proxy stuff is needed.
    #conn = httplib.HTTPConnection(proxyHost, proxyPort)
    #conn.request("POST", "http://www.google.com", params)
    host,selector = url_split(url)
    content_type, body = _encode_multipart_formdata(fields, files)
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.110 Safari/537.36',
        'Content-Type': content_type
    }
    if proxy:

        proxy_object = urlparse(proxy)
        proxy_host = proxy_object.hostname
        proxy_port = proxy_object.port

        c = httplib.HTTPConnection(proxy_host,proxy_port)
        logit("requesting " + url + " via proxy " + proxy_host + ":" + str(proxy_port))
        #logit("BODY IS " + body)
        c.request('POST', url, body, headers)
    else:

        c = httplib.HTTPConnection(host)
        logit("posting to " + host + "/" + selector)
        c.request('POST', selector, body, headers)
    res = c.getresponse()
    return res.read()

def _encode_multipart_formdata(fields, files):
    """
    Do the multipart format data for fields and files suitable for an HTTP Post doing file upload.
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
        default_content_type = 'application/octet-stream'
        contenttype = mimetypes.guess_type(filename)[0] or default_content_type
        L.append('--%s' % BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
        L.append('Content-Type: %s' % contenttype)
        fd.seek(0)
        L.append('\r\n' + fd.read())
        fd.close()
    L.append('--' + BOUNDARY + '--')
    L.append('')
    body = CRLF.join(L)
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def error_exit(msg):
    """
    Exit the program with error message limited to 1K"""
    print "ERROR: " + msg[:1024]
    if len(msg)>1024:
        print "..."
    exit(1)

def logit(s):
    """
    Log information to the user """
    if DEBUG:
        print ">>>" + s

def drop_download(code,passwd,proxy=None):
    """
    Takes a code (e.g. 772847) and a password
    Gets the file from the server, decrypts it
    and returns the filename in which it is stored.
    """
    #File comes down as .drop and text plain.
    c = Crippter(passwd)

    #e.g http://foo.com/xyz/abc.txt becomes foo.com and /xyz/abc.txt




    if proxy:
        path = DROPURL + "?action=drop_download&code=" + code
        proxy_object = urlparse(proxy)
        proxy_host = proxy_object.hostname
        proxy_port = proxy_object.port
        conn = httplib.HTTPConnection(proxy_host,proxy_port)
        logit("requesting " + path + " via proxy " + proxy_host + ":" + str(proxy_port))
        conn.request("GET", path)
    else:
        host,selector = url_split(DROPURL)
        path = selector + "?action=drop_download&code=" + code
        conn = httplib.HTTPConnection(host)
        logit("requesting " + path + " at host " + host)
        conn.request("GET", path)
    r = conn.getresponse()
    if r.status == 404:
        error_exit("The following code does not exist: " + code)
    content = r.read()
    logit("Got response")
    if r.status != 200:
        error_exit("Got HTTP Error " + str(r.status) + " " + r.reason + "\nContent:" + content)


    #Check correct content type and no whitespace
    ct = r.getheader('Content-Type')
    if (ct != 'text/plain'):
        error_exit("Content type is unexpected: " + str(ct))

    if (' ' in content):
        error_exit("Response Content cannot have whitespace: " + content)
    #logit("GOT CONTENT:" + content)
    content = content.strip()

    #logit("GOT STRIPPED CONTENT:" + content)



    conn.close()

    #Response will contain Content-Disposition with the original filename.
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






def drop_upload(filename,passwd,proxy=None):
    """
    Upload an encrypted file to the drop server
    @param filename to encrypt and upload
    @param passwd password to use for encryption
    @returns the numeric code for that file as a string"""

    c = Crippter(passwd)
    #tmp file to encrypt contents
    filename2 = filename + ".drop"
    logit("encrypting " + filename + " to " + filename2 + " with psswd " + passwd)
    c.encryptFile(filename,filename2)
    logit("Done.  Now uploading...")
    #prepar params and files for http post...
    params = [("action","drop_upload"),("secret","kerry4"),("filename",filename2)]
    files = [("drop",open(filename2,"rb"))]
    resp_content = post_multipart(DROPURL,params,files,proxy)
    logit("Done. Now deleteing " + filename2)
    os.remove(filename2)
    logit("Done.")
    if resp_content.strip().isdigit():
        return resp_content.strip()
    else:
        raise Exception("This is not a good response: " + resp_content)

def url_split(url):
    """ Split a given url into its netlocation and pat
    e.g. http://foo.com:3222/xyz/index.html becomes foo.com:3222 and /xyz/index.html
    """
    parsed_url = urlparse(url)
    return parsed_url.netloc, parsed_url.path






USAGE="""USAGE:

Step 1: Upload the file (a code will be returned to you)

  python drop.py <filename> <password>

  python drop.py foo.rpm secret



Step 2: Download the file on another machine

  python drop.py <code> <password>

  python drop.py 563372 secret

Version 0.2
Email questions, bugs, and jokes to werwath@gmail.com

"""
if len(sys.argv) < 3:
    print USAGE
    sys.exit(0)


first_arg = sys.argv[1]
passwd = sys.argv[2]


if len(sys.argv) > 3:
    proxy = sys.argv[3]
else:
    proxy = os.environ.get('HTTP_PROXY')


if first_arg.isdigit():
    code = first_arg
    drop_download(code,passwd,proxy)

elif os.path.isfile(first_arg):
    filename = first_arg
    code = drop_upload(filename,passwd,proxy)
    print "Success! Run this command to retrieve your flie:\npython drop.py %s %s\n" % (code, passwd)

else:
    print "It appears this is neither a code or a valid file name: " + first_arg
    exit


