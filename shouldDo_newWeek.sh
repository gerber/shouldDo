#!/bin/sh

#  FILENAME: shouldDo_newWeek.sh
#   VERSION: 1.7.0
#      DATE: 2011/12/22
#       URL: http://shouldDo.org
#    AUTHOR: Ben Gerber (http://privacy.us/contact ) 
# COPYRIGHT: (C) Ben Gerber 2009, 2011
#   LICENSE: Creative Commons Attribution 3.0 License (http://creativecommons.org/licenses/by/3.0/ )
#     ABOUT: This shell script is intended to be used w/ shouldDo.org v1.7.0
# This script has been tested with GNU grep version 2.9, GNU sed version 4.2.1, GNU Awk 3.1.8

# SETTINGS ########################################################################################
# Set the location of your shouldDo.org file and the location of a backup directory

shouldDoFile="/home/you/shouldDo.org"
shouldDoBakupDir="/home/you/shouldDoBakupDir/" #include the trailing slash

# END SETTINGS ####################################################################################

# basic error checking for settings ###############################################################
if [ -f $shouldDoFile ] && [ -w $shouldDoFile ]; then
    echo "shouldDoFile: $shouldDoFile"
else
    echo "ERROR: $shouldDoFile is NOT a writable file"
    exit 1
fi

if [ -d $shouldDoBakupDir ] && [ -w $shouldDoBakupDir ]; then
    echo "shouldDoBakupDir: $shouldDoBakupDir"
else
    echo "ERROR: shouldDoBakupDir is NOT a writable directory"
    exit 1
fi

# make a backup ###################################################################################
shouldDoBasename=`basename "$shouldDoFile"`
curDateTime=$(date +"%Y%m%d_%H%M%S")
shouldDoBakupFile=$shouldDoBakupDir$shouldDoBasename"_"$curDateTime

cp -p $shouldDoFile $shouldDoBakupFile

if [ -f $shouldDoBakupFile ]; then
    echo "shouldDoBakupFile: $shouldDoBakupFile"
else
    echo "ERROR: $shouldDoBakupFile is missing, backup failed"
    exit 1
fi

# get the past week's year, week #, and score #####################################################
scoreLine=`grep '^|\s#\s|\s\sy.*SCORE.*[0-9]\s|$' $shouldDoFile`
if [ `echo $scoreLine | wc -l` -ne 1 ]; then
    echo "ERROR: Problem identifying SCORE line"
    exit 1
fi

year=`echo $scoreLine | awk 'BEGIN { FS = "|" } ; { print $4 }'`
week=`echo $scoreLine | awk 'BEGIN { FS = "|" } ; { print $6 }'`
score=`echo $scoreLine | awk 'BEGIN { FS = "|" } ; { print $17 }'`

yearIsNum=`echo $year | tr -d [0-9]`
weekIsNum=`echo $week | tr -d [0-9]`
scoreIsNum=`echo $score | tr -d [0-9] | tr -d .`
if ! [ -z $yearIsNum ]; then
    echo "ERROR: Year is not a number"
    exit 1
elif ! [ -z $weekIsNum ]; then
    echo "ERROR: Week # is not a number"
    exit 1
elif ! [ -z $scoreIsNum ]; then
    echo "ERROR: Score is not a number"
    exit 1
fi

# insert the past week's year, week #, and score into the history table ###########################
if [ `grep '^|\s#\s|\syear\s|\sweek\s|.*|\sy\s|$' $shouldDoFile | wc -l` -ne 1 ]; then
    echo "ERROR: Found too many history table headers"
    exit 1
fi
historyHeaderLineNum=`grep -n '^|\s#\s|\syear\s|\sweek\s|.*|\sy\s|$' $shouldDoFile | sed 's/:.*//'`
if [ -z $historyHeaderLineNum ]; then
    echo "ERROR: Problem finding history table"
    exit 1
fi
historyInsertLineNum=`expr $historyHeaderLineNum + 2`

historyInsert="| # |$year| $week |$score|      |   |     |     |   |"
eval sed -i '"$historyInsertLineNum"i"$historyInsert"' $shouldDoFile

# reset the activities log table ##################################################################
if [ `grep '^|\s#\s|\sid\s|\sactivity.*|\spoints\s|$' $shouldDoFile | wc -l` -ne 1 ]; then
    echo "ERROR: Found too many activities log table headers"
    exit 1
fi
activitiesHeaderLineNum=`grep -n '^|\s#\s|\sid\s|\sactivity.*|\spoints\s|$' $shouldDoFile | sed 's/:.*//'`
if [ -z $activitiesHeaderLineNum ]; then
    echo "ERROR: Problem finding activities log table"
    exit 1
fi
activitiesStartLineNum=`expr $activitiesHeaderLineNum + 2`
activitiesEndLineNum=`expr $activitiesHeaderLineNum + 11`

activitiesReset=`awk 'BEGIN { FS = "|"; OFS = "|" }; { if ((NR >= '$activitiesStartLineNum') && (NR <= '$activitiesEndLineNum')) \
    { $5="    "; $6="    "; $7="    "; $8="    "; $9="    "; $10="    "; $11="    "; print } }' $shouldDoFile)`
echo "$activitiesReset" | while read line; do
    eval sed -i '"$activitiesStartLineNum"c"$line"' $shouldDoFile
    activitiesStartLineNum=`expr $activitiesStartLineNum + 1`
done

exit 0
