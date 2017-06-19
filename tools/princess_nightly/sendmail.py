#!/usr/bin/python2.7

# sendmail.py - e-mail a file with sendmail

import argparse
import datetime
import sys

from subprocess import Popen, PIPE
from email.mime.text import MIMEText

now = datetime.datetime.strftime(datetime.datetime.now(), '%c')
from_address = 'princess-nightly@nomnomnom.seas.harvard.edu'
recipients = ",".join([
    'alexanderpatel@college.harvard.edu',
    'dholland@sauclovia.org',
    'ming@g.harvard.edu',
    'ericlu01@college.harvard.edu',
    'goldstein.marik@gmail.com',
    'crystaljmhu@gmail.com',
])

# get e-mail message config
parser = argparse.ArgumentParser(description='use sendmail to send a file')
parser.add_argument('-f', '--file', type=str, help='file name', required=True)

args = parser.parse_args()

# construct e-mail 
fp = open(args.file, 'rb')
msg = MIMEText(fp.read())
fp.close()
msg['Subject'] = 'PRINCESS nightly build (%s)' % (now)
msg['From'] = from_address
msg['To'] = recipients

# send e-mail with sendmail
p = Popen(["/usr/sbin/sendmail", "-t", "-oi"], stdin=PIPE)
p.communicate(msg.as_string())
