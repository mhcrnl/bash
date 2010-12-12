#!/bin/bash
#
# A bash script by JoeD - Joe84D@gmail.com
# 
# Commiting changes to git with one easy step.

check_passwords
if [ $? == 1 ]; then exit; fi

DATE=`date +%Y.%m.%d_%H:%M`
if [[ $1 = "" ]];
  then
    MESSAGE="$DATE - Scripted push"
  else
    MESSAGE="$DATE - $1"
fi

git add .
git commit -m "$MESSAGE"
git push
