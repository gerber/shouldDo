#!/usr/bin/python

#  FILENAME: shouldDo_newWeek.py
#   VERSION: 1.7.1
#      DATE: 2011/12/26
#       URL: http://shouldDo.org
#    AUTHOR: Ben Gerber (http://privacy.us/contact ) 
# COPYRIGHT: (C) Ben Gerber 2009, 2011
#   LICENSE: Creative Commons Attribution 3.0 License (http://creativecommons.org/licenses/by/3.0/ )
#     ABOUT: This Python script is intended to be used w/ shouldDo.org v1.7.0 and v1.7.1
# This script has been tested with Python version 2.7.2 on Ubuntu and version 2.7.1 on Mac OS X

# SETTINGS ########################################################################################
# Set the location of your shouldDo.org file and the location of a backup directory

shouldDoFile = '/home/you/shouldDo.org'
shouldDoBakupDir = '/home/you/shouldDoBakupDir' # trailing slash is optional

# END SETTINGS ####################################################################################

import os, datetime, shutil, sys, re, fileinput

# make a backup ###################################################################################
shouldDoBasename = os.path.basename(shouldDoFile)
shouldDoBakupFile = shouldDoBasename + '_' + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
shouldDoBakupFile = os.path.join(shouldDoBakupDir, shouldDoBakupFile)

try:
    shutil.copy2(shouldDoFile, shouldDoBakupFile)
except:
    print "ERROR: unable to make backup, check permissions and your SETTINGS:\n" + \
        "shouldDoFile: " + shouldDoFile + '\n' + \
        "shouldDoBakupDir: " + shouldDoBakupDir + '\n' + \
        "exiting"
    sys.exit(1)

# get the past week's year, week #, and score #####################################################
sdFile = open( shouldDoFile,'r'); sdLines = sdFile.readlines(); sdFile.close()
sdLineNum = len(sdLines)

scoreLineRe = re.compile('^\|\s#\s\|\s\sy.*SCORE.*[0-9]\s\|$')
n=0
for sdLine in sdLines:
    if scoreLineRe.match(sdLine):
        n=n+1
        scoreLine = sdLine
if n==0: print "ERROR: SCORE line NOT found, exiting"; sys.exit(1)
if n>1: print "WARNING: " + str(n) + " SCORE lines found, using last one"

scoreLine = scoreLine.split('|')
year=scoreLine[3].strip()
if not year.isdigit(): print "ERROR: Year is not a number, exiting"; sys.exit(1)
week=scoreLine[5].strip()
if not week.isdigit(): print "ERROR: Week # is not a number, exiting"; sys.exit(1)
score=scoreLine[16].strip()
if not score.replace('.','',1).isdigit(): print "ERROR: Score is not a number, exiting"; sys.exit(1)

# insert the past week's year, week #, and score into the history table ###########################
historyHeaderLineRe = re.compile('^\|\s#\s\|\syear\s\|\sweek\s\|.*\|\sy\s\|$')
historyInsert="| # | " + year + " |   " + week + " | " + score + " |      |   |     |     |   |"
n=0; i=0; historyHeaderLineNum=(sdLineNum+1000)
for sdLine in fileinput.input(shouldDoFile, inplace=1):
    print sdLine,
    if historyHeaderLineRe.match(sdLine):
        n=n+1
        historyHeaderLineNum = i
    if fileinput.filelineno() == (historyHeaderLineNum + 2):
        print historyInsert
    i=i+1
if n==0: print "ERROR: History table header line NOT found, exiting"; sys.exit(1)
if n>1: print "WARNING: " + str(n) + " History table header lines found, updated ALL history tables"

# reset the activities log table ##################################################################
activitiesHeaderLineRe = re.compile('^\|\s#\s\|\sid\s\|\sactivity.*\|\spoints\s\|$')
n=0; i=0; activitiesHeaderLineNum=(sdLineNum+1000)
for sdLine in fileinput.input(shouldDoFile, inplace=1):
    if activitiesHeaderLineRe.match(sdLine):
        n=n+1
        activitiesHeaderLineNum = i
    if (fileinput.filelineno() >= (activitiesHeaderLineNum + 3)) & \
            (fileinput.filelineno() <= (activitiesHeaderLineNum + 12)):
        activitiesLine = sdLine.split('|')
        activitiesLine[4] = "    "
        activitiesLine[5] = "    "
        activitiesLine[6] = "    "
        activitiesLine[7] = "    "
        activitiesLine[8] = "    "
        activitiesLine[9] = "    "
        activitiesLine[10] = "    "
        print '|'.join(activitiesLine),
    else:
        print sdLine,
    i=i+1
if n==0: print "ERROR: Activities log table header line NOT found, exiting"; sys.exit(1)
if n>1: print "WARNING: " + str(n) + " Activities log table header lines found, reset ALL activities tables"

sys.exit(0)
