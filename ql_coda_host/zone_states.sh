#!/bin/bash
# prints whether the sink for each of a list of player zone is IDLE, SUSPENDED or RUNNING
# eg
# zone_states.sh Balcony Dining  ==>
# Zone Balcony SUSPENDED
# Zone Dining RUNNING
#
# requires zone_sink_name.sh, zone_sink_state.sh
#
if [ $# -eq 0 ]
  then
    echo "no zone"
    exit 1
else
  read -ra array <<< "$1"
  zonestates=()
  echo '{ "zonestates": {'
  for zone in "${array[@]}"
    do
      #echo "$(/home/david/bin/zone_sink_state.sh $zone)"
      state=$(/home/david/bin/zone_sink_state.sh $zone)
      zonestates=(${zonestates[@]} $state)
    done
  printf "%s," "${zonestates[@]}" | cut -d "," -f 1-${#zonestates[@]}
  #echo "${zonestates[@]}"
  echo '}}'
  exit 0
fi
