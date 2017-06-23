#!/usr/bin/python2.7

# sendmail.py - e-mail contents of build  file with sendmail

import argparse
import datetime
import sys

from subprocess import Popen, PIPE
from email.mime.text import MIMEText

now = datetime.datetime.strftime(datetime.datetime.now(), '%c')
from_address = 'princess-nightly@nomnomnom.seas.harvard.edu'
recipients = ",".join([
    'patelalex02@gmail.com',
    'dholland@sauclovia.org',
    'ming@g.harvard.edu',
    'ericlu01@college.harvard.edu',
    'goldstein.marik@gmail.com',
    'crystaljmhu@gmail.com',
])

parser = argparse.ArgumentParser(description='use sendmail to send a file')
parser.add_argument('-f', '--file', type=str, help='file name', required=True)
parser.add_argument('-s', '--subject', type=str, help='e-mail subject', required=True)
args = parser.parse_args()

with open(args.file, 'rb') as f:
    contents = f.read()
    msg = MIMEText(contents)
    msg['Subject'] = args.subject
    msg['From'] = from_address
    msg['To'] = recipients

    p = Popen(["/usr/sbin/sendmail", "-t", "-oi"], stdin=PIPE)
    p.communicate(msg.as_string())
