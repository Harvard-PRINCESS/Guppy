#!/usr/bin/python2.7

# sendmail.py - e-mail a file with sendmail

import argparse
import datetime
import sys

from subprocess import Popen, PIPE
from email.mime.text import MIMEText


now = datetime.datetime.strftime(datetime.datetime.now(), '%c')

# get e-mail message config
parser = argparse.ArgumentParser(description='use sendmail to send a file')
parser.add_argument('-f', '--file', type=str, help='file name', required=True)
parser.add_argument('-e', '--email', type=str, help='e-mail from address',
                    required=True)
parser.add_argument('-t', '--to', type=str, help='to', required=True)

args = parser.parse_args()

# construct e-mail 
fp = open(args.file, 'rb')
msg = MIMEText(fp.read())
fp.close()
msg['Subject'] = 'PRINCESS nightly build (%s)' % (now)
msg['From'] = args.email
msg['To'] = args.to

# send e-mail with sendmail
p = Popen(["/usr/sbin/sendmail", "-t", "-oi"], stdin=PIPE)
p.communicate(msg.as_string())
