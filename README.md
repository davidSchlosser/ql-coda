# ql-coda
A remote browser and controller for the Quodlibet music player. 
Features:
view currrent track, progress bar, volume control, skip next or previous track.
edit track tags and view metadata.
view playlist.
browse albums, create filter using Quodlibet queries , browse tracks
add albums and tracks to Quodlibet queue.
browse queue, remove tracks from queue.


Dependencies:
Quodlibet 4.6
Quodlibet MQTT plugin
MQTT tranport (eg 
Mosquitto)
ql-coda-host running on the Quodlibet host 
Android

Untested:
ql-coda-host is written in Python so should run on any platform Quodlibet runs on.
ql-coda is written in Flutter and Dart so should be deployaable
 to iOS, web, and desktops where Flutter is suported.
