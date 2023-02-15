#!/bin/bash
# prints whether the sink for a player zone is IDLE, SUSPENDED or RUNNING
# eg
# zone_sink_state.sh Balcony  ==>  Zone Balcony IDLE
#
# requires zone_sink_name.sh
#
if [ $# -eq 0 ]
  then
    echo "no zone"
    exit 1
else
  sink="$(~/bin/zone_sink_name.sh $1 )"
  #echo -n $sink
  if [ -z "$sink" ]
  then
    echo "no sink: " $1
    exit 1
  fi
fi
#echo -n Zone $1 $sink ''
#echo -n '{"'$1'":'
echo -n '"'$1'":'
pactl list sinks short | awk '
{ if (match($0, "'$sink'\t"))   # card names are followed by <tab>, handles card names formed by adding suffix to similar card
	{ print "\""$7"\"" }
}'
#echo -n '}'
