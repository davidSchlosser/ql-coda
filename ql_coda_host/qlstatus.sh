#!/bin/bash
#
QL=/home/david/quodlibet/quodlibet.py
QLSTATUS=$($QL --status)
#echo $QLSTATUS
#exit 0

#echo $QL
echo '{ "status": "'$(/home/david/quodlibet/quodlibet.py --status)'"}'
#echo '{ "status": "'$QLSTATUS'"}'
exit 0
