#!/usr/bin/env python
import imaplib, sys, getpass
import getopt

email = None
server = None
mailbox = 'INBOX'

def usage():
    sys.stderr.write("""
    getpatch.py: fetch a number of patches from your email account

    getpatch.py [options] subject1 [subject2]...

    OPTIONS:
    -e:       email address to fetch from
    -s:       imap server hosting email account
    -m:       mailbox name [defaults to INBOX]
    """)

try:
    opts, args = getopt.getopt(sys.argv[1:], "e:s:m:", ["email=", "server=", "mailbox="])
except getopt.GetoptError, err:
    print str(err)
    usage()
    sys.exit(1)

for o, a in opts:
    if o in ("-e", "--email"):
        email = a
    elif o in ("-s", "--server"):
        server = a
    elif o in ("-m", "--mailbox"):
        mailbox = a
    else:
        assert False, "unhandled option"

if email == None or server == None:
    sys.stderr.write("email and server args are required\n")
    sys.exit(1)

password = getpass.getpass()

M = imaplib.IMAP4_SSL(server, 993)
M.login(email, password)
M.select(mailbox)

count = 1
for a in args:
    filename = a.replace("[", "").replace("] ", "-").replace("/", "-").replace(" ", "-").replace(": ", "-").replace(":", "-")
    filename = "%04d-" % count + filename + ".patch"
    count += 1
    print "Fetching patch " + filename
    f = open(filename, "w")
    terms = '(SUBJECT "' + a + '")'
    typ, data = M.search(None, terms)
    nums = data[0].split()
    if len(nums) == 0:
        print "Failed to find message with that subject."
        sys.exit(1)
		
    elif len(nums) != 1:
        print "Found %d messages matching subject line.  Please refine." % len(nums)
        sys.exit(1)

    typ, data = M.fetch(nums[0], '(RFC822)')
    f.write(data[0][1])
    f.close

M.close()
M.logout()
