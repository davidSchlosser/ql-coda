#!/bin/bash
# prints the name of the pulseaudio sink that has  a given description
# eg
# get_sink_name.sh Balcony  ==> alsa_output.usb-TOPPING_VX1-00.analog-stereo.2
#
#echo -n "-"$1"-"
index="\"$1\""
#echo $1
#echo $index
pacmd list-sinks | grep -e 'name:' -e 'index:' -e 'device.description' | awk '
BEGIN { 
	RS="index: "
} 
{ if ( match($0, '$index' )) 
	{ print substr($3,2,length($3)-2) }
} '
