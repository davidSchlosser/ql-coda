#!/bin/bash
# suspend the sink for a player zone 
# eg
# zone_suspend.sh Balcony
#
# requires zone_sink_name.sh
#
if [ $# -eq 0 ]
  then
    echo "no zone"
    exit 1
else
  index="\"$1\""
  sink="$(~/bin/zone_sink_name.sh $1 )"
  if [ -z "$sink" ]
  then
    echo "no sink"
    exit 1
  fi
fi
#echo $sink
pactl suspend-sink $sink 1

