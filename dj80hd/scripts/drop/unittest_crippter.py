#-------------------------------------------------------------------------------
# Name:        module1
# Purpose:
#
# Author:      werwath
#
# Created:     06/09/2011
# Copyright:   (c) werwath 2011
# Licence:     <your licence>
#-------------------------------------------------------------------------------
#!/usr/bin/env python

import unittest
import filecmp
from crippter import Crippter
import os

class testCrippter(unittest.TestCase):
    def setUp(self):
        self.password = 'secret'



    def testString(self):
        message = "This is a secret for jo jo bolonga!!!!"
        c = Crippter(self.password)
        encoded_message = c.encryptString(message)
        #print "GOT:"+encoded_message
        decoded_message = Crippter(self.password).decryptString(encoded_message)
        #print "Original String: %s\nKey: %s\nHash: %s\nDecrypted String: %s\nEqual?: %s"%(message, self.password, encoded_message, decoded_message, message==decoded_message)
        self.assertEqual(message, decoded_message)

    def testFile(self):
        c = Crippter(self.password)
        c.encryptFile('pain.mp3','encrypted_pain.mp3')
        c.decryptFile('encrypted_pain.mp3','decrypted_pain.mp3')
        self.assertTrue(filecmp.cmp('decrypted_pain.mp3','pain.mp3'))
        #FIXME - Delete files that were created.

if __name__ == '__main__':
    '''
    s = unittest.TestSuite()
    s.addTest(testCrippter("testString"))
    s.addTest(testCrippter("testFile"))
    unittest.TextTestRunner(verbosity=2).run(suite())
    '''
    unittest.main()
    os.remove("encrypted_pain.mp3")
    os.remove("decrypted_pain.mp3")